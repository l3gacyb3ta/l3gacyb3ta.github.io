/*
 * Mirror blog posts to atproto as standard.site records.
 *
 * Reads out/posts.json (emitted by aethopica) and upserts one
 * site.standard.document per post, plus a single site.standard.publication,
 * into the account's PDS repo. Zero dependencies; Node 20+.
 *
 * Env:
 *   ATPROTO_HANDLE       e.g. arcades.agency or l3gacy.bsky.social
 *   ATPROTO_APP_PASSWORD an app password, NOT the account password
 *   ATPROTO_PDS_URL      optional, defaults to https://bsky.social
 *   DRY_RUN              set to anything to print planned records and exit
 *
 * Record keys are the post filenames, so re-runs are idempotent upserts.
 * Caveats (by design):
 *   - renaming a post changes its rkey; the old record lingers on the PDS
 *   - posts removed from the site are left on the PDS (deleting would break
 *     inbound at:// references); they're listed so removal stays a visible,
 *     manual `deleteRecord` decision
 */

import { readFileSync, existsSync } from "node:fs";
import { createHash } from "node:crypto";

const PUBLICATION = "site.standard.publication";
const DOCUMENT = "site.standard.document";
const WELL_KNOWN = "out/.well-known/site.standard.publication";

const pds = (process.env.ATPROTO_PDS_URL || "https://bsky.social").replace(/\/$/, "");
const handle = process.env.ATPROTO_HANDLE;
const password = process.env.ATPROTO_APP_PASSWORD;
const dryRun = !!process.env.DRY_RUN;

const index = JSON.parse(readFileSync("out/posts.json", "utf8"));

async function xrpc(nsid, { params, body, bodyBytes, contentType, jwt } = {}) {
  const url = new URL(`${pds}/xrpc/${nsid}`);
  for (const [k, v] of Object.entries(params || {})) url.searchParams.set(k, v);
  const res = await fetch(url, {
    method: body || bodyBytes ? "POST" : "GET",
    headers: {
      ...(bodyBytes ? { "content-type": contentType } : body ? { "content-type": "application/json" } : {}),
      ...(jwt ? { authorization: `Bearer ${jwt}` } : {}),
    },
    body: bodyBytes ?? (body ? JSON.stringify(body) : undefined),
  });
  if (!res.ok) {
    const err = new Error(`${nsid}: ${res.status} ${await res.text()}`);
    err.status = res.status;
    throw err;
  }
  return res.json();
}

/* CIDv1 (raw, sha2-256) as the PDS computes for blobs; lets us compare a
   local image against a record's existing coverImage without re-uploading */
function blobCid(bytes) {
  const digest = createHash("sha256").update(bytes).digest();
  const cid = Buffer.concat([Buffer.from([0x01, 0x55, 0x12, 0x20]), digest]);
  const alpha = "abcdefghijklmnopqrstuvwxyz234567";
  let bits = 0, value = 0, out = "";
  for (const byte of cid) {
    value = (value << 8) | byte;
    bits += 8;
    while (bits >= 5) { out += alpha[(value >>> (bits - 5)) & 31]; bits -= 5; }
  }
  if (bits > 0) out += alpha[(value << (5 - bits)) & 31];
  return "b" + out;
}

function localImage(post) {
  if (!post.image) return null;
  const path = `out${post.image}`;
  if (!existsSync(path)) return null;
  const bytes = readFileSync(path);
  if (bytes.length > 950_000) {
    console.warn(`WARNING: ${path} exceeds the ~1MB coverImage limit, skipping`);
    return null;
  }
  return { path, bytes, cid: blobCid(bytes) };
}

function documentFor(post, publicationUri) {
  return {
    $type: DOCUMENT,
    site: publicationUri,
    path: post.path,
    title: post.title,
    description: post.description,
    publishedAt: post.publishedAt,
  };
}

/* fields we own; anything else on the record (tags set by another
   client, ...) is preserved and ignored in the comparison */
const MANAGED = ["site", "path", "title", "description", "publishedAt"];

function sameManagedFields(existing, desired) {
  if (!MANAGED.every((k) => existing[k] === desired[k])) return false;
  return existing.coverImage?.ref?.$link === desired.coverImage?.ref?.$link;
}

async function main() {
  if (dryRun) {
    console.log(`DRY RUN: would sync ${index.posts.length} post(s) for ${index.site}`);
    console.log(JSON.stringify({
      publication: { $type: PUBLICATION, url: index.site, name: "aethopica" },
      documents: index.posts.map((p) => {
        const img = localImage(p);
        return {
          rkey: p.rkey,
          ...documentFor(p, "at://<did>/site.standard.publication/<rkey>"),
          coverImage: img ? `${img.path} (${img.bytes.length} bytes, ${img.cid})` : "(none)",
        };
      }),
    }, null, 2));
    return;
  }
  if (!handle || !password) throw new Error("ATPROTO_HANDLE and ATPROTO_APP_PASSWORD are required");

  const session = await xrpc("com.atproto.server.createSession", {
    body: { identifier: handle, password },
  });
  const { did, accessJwt: jwt } = session;

  /* publication: reuse whatever exists (it may have been made by another
     standard.site client with theme/icon we shouldn't clobber) */
  let publicationUri;
  const pubs = await xrpc("com.atproto.repo.listRecords", {
    params: { repo: did, collection: PUBLICATION, limit: 10 },
    jwt,
  });
  if (pubs.records.length > 0) {
    publicationUri = pubs.records[0].uri;
  } else {
    await xrpc("com.atproto.repo.putRecord", {
      body: {
        repo: did,
        collection: PUBLICATION,
        rkey: "self",
        record: {
          $type: PUBLICATION,
          url: index.site,
          name: "aethopica",
          description: "Arcade Wise's website",
        },
      },
      jwt,
    });
    publicationUri = `at://${did}/${PUBLICATION}/self`;
    console.log(`created publication ${publicationUri}`);
  }
  console.log(`publication: ${publicationUri}`);

  /* the site must serve this URI at /.well-known/site.standard.publication
     for verification; that file is committed at data/static/ */
  if (!existsSync(WELL_KNOWN)) {
    console.warn(`WARNING: ${WELL_KNOWN} missing; create data/static/.well-known/site.standard.publication containing: ${publicationUri}`);
  } else {
    const served = readFileSync(WELL_KNOWN, "utf8").trim();
    if (served !== publicationUri)
      console.warn(`WARNING: ${WELL_KNOWN} contains "${served}" but the publication is ${publicationUri}`);
  }

  let created = 0, updated = 0, unchanged = 0;
  for (const post of index.posts) {
    const desired = documentFor(post, publicationUri);
    let existing = null;
    try {
      const res = await xrpc("com.atproto.repo.getRecord", {
        params: { repo: did, collection: DOCUMENT, rkey: post.rkey },
        jwt,
      });
      existing = res.value;
    } catch (e) {
      if (e.status !== 400 && e.status !== 404) throw e;
    }
    const img = localImage(post);
    if (img) {
      if (existing?.coverImage?.ref?.$link === img.cid) {
        desired.coverImage = existing.coverImage;
      } else {
        const up = await xrpc("com.atproto.repo.uploadBlob", {
          bodyBytes: img.bytes,
          contentType: "image/png",
          jwt,
        });
        desired.coverImage = up.blob;
        console.log(`uploaded ${img.path} (${img.bytes.length} bytes)`);
      }
    } else if (existing?.coverImage) {
      /* no local image: keep whatever the record already has */
      desired.coverImage = existing.coverImage;
    }
    if (existing && sameManagedFields(existing, desired)) {
      unchanged++;
      continue;
    }
    await xrpc("com.atproto.repo.putRecord", {
      body: {
        repo: did,
        collection: DOCUMENT,
        rkey: post.rkey,
        record: { ...(existing || {}), ...desired },
      },
      jwt,
    });
    existing ? updated++ : created++;
    console.log(`${existing ? "updated" : "created"} ${post.rkey}`);
  }

  /* surface records that no longer correspond to a post; never delete */
  const local = new Set(index.posts.map((p) => p.rkey));
  const remote = await xrpc("com.atproto.repo.listRecords", {
    params: { repo: did, collection: DOCUMENT, limit: 100 },
    jwt,
  });
  for (const rec of remote.records) {
    const rkey = rec.uri.split("/").pop();
    if (!local.has(rkey))
      console.log(`note: ${rkey} exists on the PDS but not in posts.json (left as-is)`);
  }

  console.log(`done: ${created} created, ${updated} updated, ${unchanged} unchanged`);
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
