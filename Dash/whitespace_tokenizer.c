#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "whitespace_tokenizer.h"

static int whitespaceDelim(whitespace_tokenizer *t, unsigned char c){
    return c == ' ' || c == '*';
}

/*
 ** Create a new tokenizer instance.
 */
int whitespaceCreate(
                        int argc, const char * const *argv,
                        sqlite3_tokenizer **ppTokenizer
                        ){
    whitespace_tokenizer *t;
    t = (whitespace_tokenizer *) sqlite3_malloc(sizeof(*t));
    if( t==NULL ) return SQLITE_NOMEM;
    memset(t, 0, sizeof(*t));
    
    *ppTokenizer = &t->base;
    return SQLITE_OK;
}

/*
 ** Destroy a tokenizer
 */
int whitespaceDestroy(sqlite3_tokenizer *pTokenizer){
    sqlite3_free(pTokenizer);
    return SQLITE_OK;
}

/*
 ** Prepare to begin tokenizing a particular string.  The input
 ** string to be tokenized is pInput[0..nBytes-1].  A cursor
 ** used to incrementally tokenize this string is returned in
 ** *ppCursor.
 */
int whitespaceOpen(
                      sqlite3_tokenizer *pTokenizer,         /* The tokenizer */
                      const char *pInput, int nBytes,        /* String to be tokenized */
                      sqlite3_tokenizer_cursor **ppCursor    /* OUT: Tokenization cursor */
                      ){
    whitespace_tokenizer_cursor *c;
        
    c = (whitespace_tokenizer_cursor *) sqlite3_malloc(sizeof(*c));
    if( c==NULL ) return SQLITE_NOMEM;
    
    c->pInput = pInput;
    if( pInput==0 ){
        c->nBytes = 0;
    }else if( nBytes<0 ){
        c->nBytes = (int)strlen(pInput);
    }else{
        c->nBytes = nBytes;
    }
    c->iOffset = 0;                 /* start tokenizing at the beginning */
    c->iToken = 0;
    c->pToken = NULL;               /* no space allocated, yet. */
    c->nTokenAllocated = 0;
    
    *ppCursor = &c->base;
    return SQLITE_OK;
}

/*
 ** Close a tokenization cursor previously opened by a call to
 ** whitespaceOpen() above.
 */
int whitespaceClose(sqlite3_tokenizer_cursor *pCursor){
    whitespace_tokenizer_cursor *c = (whitespace_tokenizer_cursor *) pCursor;
    sqlite3_free(c->pToken);
    sqlite3_free(c);
    return SQLITE_OK;
}

/*
 ** Extract the next token from a tokenization cursor.  The cursor must
 ** have been opened by a prior call to whitespaceOpen().
 */
int whitespaceNext(
                      sqlite3_tokenizer_cursor *pCursor,  /* Cursor returned by whitespaceOpen */
                      const char **ppToken,               /* OUT: *ppToken is the token text */
                      int *pnBytes,                       /* OUT: Number of bytes in token */
                      int *piStartOffset,                 /* OUT: Starting offset of token */
                      int *piEndOffset,                   /* OUT: Ending offset of token */
                      int *piPosition                     /* OUT: Position integer of token */
                      ){
    whitespace_tokenizer_cursor *c = (whitespace_tokenizer_cursor *) pCursor;
    whitespace_tokenizer *t = (whitespace_tokenizer *) pCursor->pTokenizer;
    unsigned char *p = (unsigned char *)c->pInput;
    
    while( c->iOffset<c->nBytes ){
        int iStartOffset;
        
        /* Scan past delimiter characters */
        while( c->iOffset<c->nBytes && whitespaceDelim(t, p[c->iOffset]) ){
            c->iOffset++;
        }
        
        /* Count non-delimiter characters. */
        iStartOffset = c->iOffset;
        while( c->iOffset<c->nBytes && !whitespaceDelim(t, p[c->iOffset]) ){
            c->iOffset++;
        }
        
        if( c->iOffset>iStartOffset ){
            int i, n = c->iOffset-iStartOffset;
            if( n>c->nTokenAllocated ){
                char *pNew;
                c->nTokenAllocated = n+20;
                pNew = sqlite3_realloc(c->pToken, c->nTokenAllocated);
                if( !pNew ) return SQLITE_NOMEM;
                c->pToken = pNew;
            }
            for(i=0; i<n; i++){
                /* TODO(shess) This needs expansion to handle UTF-8
                 ** case-insensitivity.
                 */
                unsigned char ch = p[iStartOffset+i];
                c->pToken[i] = (char)((ch>='A' && ch<='Z') ? ch-'A'+'a' : ch);
            }
            *ppToken = c->pToken;
            *pnBytes = n;
            *piStartOffset = iStartOffset;
            *piEndOffset = c->iOffset;
            *piPosition = c->iToken++;
            
            return SQLITE_OK;
        }
    }
    return SQLITE_DONE;
}

/*
 ** Allocate a new whitespace tokenizer.  Return a pointer to the new
 ** tokenizer in *ppModule
 */
void sqlite3Fts3WhitespaceTokenizerModule(
                                      sqlite3_tokenizer_module const**ppModule
                                      ){
    *ppModule = &whitespaceTokenizerModule;
}

void rankfunc(sqlite3_context *pCtx, int nVal, sqlite3_value **apVal){
    unsigned int *aMatchinfo;       /* Return value of matchinfo() */
    int nCol;                       /* Number of columns in the table */
    int nPhrase;                    /* Number of phrases in the query */
    int iPhrase;                    /* Current phrase */
    double score = 0.0;             /* Value to return */

    /* Check that the number of arguments passed to this function is correct.
     ** If not, jump to wrong_number_args. Set aMatchinfo to point to the array
     ** of unsigned integer values returned by FTS function matchinfo. Set
     ** nPhrase to contain the number of reportable phrases in the users full-text
     ** query, and nCol to the number of columns in the table.
     */
    aMatchinfo = (unsigned int *)sqlite3_value_blob(apVal[0]);
    nPhrase = aMatchinfo[0];
    nCol = aMatchinfo[1];
    if ( (nVal - 1) > nCol ) goto wrong_number_args;
    
    
    /* Iterate through each phrase in the users query. */
    for(iPhrase=0; iPhrase<nPhrase; iPhrase++){
        
        /* Now iterate through each column in the users query. For each column,
         ** increment the relevancy score by:
         **
         **   (<hit count> / <global hit count>) * <column weight>
         **
         ** aPhraseinfo[] points to the start of the data for phrase iPhrase. So
         ** the hit count and global hit counts for each column are found in
         ** aPhraseinfo[iCol*3] and aPhraseinfo[iCol*3+1], respectively.
         */
        unsigned int *aPhraseinfo = &aMatchinfo[2 + iPhrase*nCol*3];
        int iCol = 1;
        int nHitCount = aPhraseinfo[3*iCol];
        if( nHitCount>0 )
        {
            score += 1;
        }
    }
    
    sqlite3_result_double(pCtx, score);
    return;
    
    /* Jump here if the wrong number of arguments are passed to this function */
wrong_number_args:
    sqlite3_result_error(pCtx, "wrong number of arguments to function rank()", -1);
}

void dashCompress(sqlite3_context *context, int argc, sqlite3_value **argv){
    if(argc == 1)
    {
        const char *text = (const char*)sqlite3_value_text(argv[0]);
        for(int i = 0; text[i] != '\0'; i++)
        {
            if(text[i] == ' ')
            {
                char compressed[i+3];
                compressed[0] = '`';
                compressed[1] = '`';
                memcpy(compressed+2, text, i);
                compressed[i+2] = '\0';
                sqlite3_result_text(context, compressed, -1, SQLITE_TRANSIENT);
                return;
            }
        }
        sqlite3_result_text(context, text, -1, SQLITE_TRANSIENT);
        return;
    }
    sqlite3_result_null(context);
}

void dashUncompress(sqlite3_context *context, int argc, sqlite3_value **argv){
    if(argc == 1)
    {
        const char *text = (const char*)sqlite3_value_text(argv[0]);
        size_t len = strlen(text);
        if(len > 2 && text[0] == '`' && text[1] == '`')
        {
            size_t actualLen = len-2;
            size_t suffixLength = ((actualLen*(actualLen+1))/2)+actualLen+1;
            char suffix[suffixLength];
            int suffixIndex = 0;
            for(int i = 2; i < len; i++)
            {
                for(int j = i; j < len; j++)
                {
                    suffix[suffixIndex] = text[j];
                    ++suffixIndex;
                }
                if(text[i] == '`')
                {
                    for(int j = i+1; j < len; j++)
                    {
                        if(text[j] == '`')
                        {
                            i = j;
                            break;
                        }
                    }
                }
                if(i+1<len)
                {
                    suffix[suffixIndex] = ' ';
                    ++suffixIndex;
                }
            }
            suffix[suffixIndex] = '\0';
            sqlite3_result_text(context, suffix, -1, SQLITE_TRANSIENT);
        }
        else
        {
            sqlite3_result_text(context, text, -1, SQLITE_TRANSIENT);
        }
        return;
    }
    sqlite3_result_null(context);
}


