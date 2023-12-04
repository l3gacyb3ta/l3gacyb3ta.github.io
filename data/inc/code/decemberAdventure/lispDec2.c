/* clang-format off */
int   slen(char *s) { int i = 0; while (s[i] && s[++i]) { i = i; } return i; } /* string length */
char *ccat(char *dst, char c) { int len = slen(dst); dst[len] = c; dst[len + 1] = 0; return dst; } /* char concatenate */
int   scmp(char *a, char *b) { int i = 0; while(a[i] == b[i]) if(!a[i++]) return 1; return 0; } /* string compare */
int   ssin(char *s, char *ss) { int a = 0; int b = 0; while(s[a]) { if(s[a] == ss[b]) { if(!ss[b + 1]) return a - b; b++; } else b = 0; a++; } return -1; } /* string substring index */
/* clang-format on */

#define BUFLEN 100

char getc()
{
    return fgetc(Console());
}

void print_str(char *s)
{
    int i = 0;
    char c = s[0];
    while (c != 0)
    {
        fputc(s[i], Console());
        c = s[++i];
    }
}

char strbuf[BUFLEN];

char *readl()
{
    char c;
    int len = 0;
    char *str = strbuf;

    while (len < BUFLEN)
    {
        c = getc();

        ccat(str, c);
        len++;

        if (len >= 99)
        {
            return str;
        }

        if (c == 10)
        {
            return str;
        }
    }
}

char *eval(char *input)
{
    return input;
}

char *print(char *input)
{
    // puts(") ");
    print_str(input);
    return input;
}

void repl()
{
    int i;
    char *str = strbuf;

    while (ssin(str, ",q") >= 0)
    {
        memset((int *)strbuf, 0, BUFLEN);
        print(eval(readl()));
    }
}