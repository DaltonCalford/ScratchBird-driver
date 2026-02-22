#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

SEXP C_sb_tls_connect(SEXP hostSEXP,
                      SEXP portSEXP,
                      SEXP sslmodeSEXP,
                      SEXP rootCertSEXP,
                      SEXP certSEXP,
                      SEXP keySEXP,
                      SEXP passwordSEXP,
                      SEXP connectTimeoutSEXP,
                      SEXP socketTimeoutSEXP);
SEXP C_sb_tls_write(SEXP extptr, SEXP payloadSEXP);
SEXP C_sb_tls_read_exact(SEXP extptr, SEXP nSEXP);
SEXP C_sb_tls_close(SEXP extptr);

static const R_CallMethodDef callMethods[] = {
    {"C_sb_tls_connect",   (DL_FUNC) &C_sb_tls_connect,   9},
    {"C_sb_tls_write",     (DL_FUNC) &C_sb_tls_write,     2},
    {"C_sb_tls_read_exact",(DL_FUNC) &C_sb_tls_read_exact,2},
    {"C_sb_tls_close",     (DL_FUNC) &C_sb_tls_close,     1},
    {NULL, NULL, 0}
};

void R_init_scratchbird(DllInfo* info) {
    R_registerRoutines(info, NULL, callMethods, NULL, NULL);
    R_useDynamicSymbols(info, FALSE);
}
