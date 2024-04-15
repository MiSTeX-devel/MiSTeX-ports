#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void dump(char *);
char *read_ROM(FILE *f);
char *read_MRA(FILE *f);

int main(int argc, char *argv[]) {
    FILE *f=NULL;
    int k, mra_mode=0;
    char *rom = NULL;

    for( k=1; k<argc; k++ ) {
        if( argv[k][0]!='-') {
            if( f==NULL) {
                f=fopen(argv[k],"rb");
                if( !f ) {
                    printf("Cannot open file %s\n", argv[1]);
                    return 1;
                }
            } else {
                puts("Cannot specified two file names.");
                return 1;
            }
            continue;
        }
        if( strcmp( argv[k], "-mra")==0 ) {
            mra_mode = 1;
            continue;
        }
        if( strcmp( argv[k], "-h") == 0 || strcmp(argv[k],"-help")==0 ) {
            puts(
                "Usage: okidump filename [-mra]"
                "       the file name points to either a direct OKI ROM or"
                "       to a .rom file generated for the JTCPS core using an MRA"
            );
            return 0;
        }
        printf("Unrecognized argument %s\n", argv[k]);
        return 1;
    }
    if( argc < 2 || f==NULL) {
        printf("ERROR: expecting a file name as the ROM argument\n");
        return 1;
    }

    if( mra_mode )
        rom = read_MRA(f);
    else
        rom = read_ROM(f);
    fclose(f);

    if( rom != NULL ) {
        dump( rom );
        free( rom );
        return 0;
    } else
        return 1;
}

char *read_MRA(FILE *f) {
    char off0[2], off1[2];
    size_t rdcnt;
    int start, end;
    fseek( f, 2, SEEK_SET );
    rdcnt  = fread( off0, 1, 2, f );
    rdcnt += fread( off1, 1, 2, f );
    if( rdcnt!= 4 ) {
        printf("Cannot read header from MRA file (%ld bytes read)\n", rdcnt);
        return NULL;
    }
    start = (off0[0]&0xff) | ((off0[1]&0xff)<<8);
    end   = (off1[0]&0xff) | ((off1[1]&0xff)<<8);
    start <<= 10;
    end   <<= 10;
    if( end <= start ) {
        puts("Wrong MRA header. The end address is lower than the start");
        return NULL;
    }
    if( (end-start)>256*1024 ) {
        puts("ADPCM ROM is larger than 256kB");
        return NULL;
    }
    char *rom = malloc( 4*64*1024 );
    memset( rom, 0, 256*1024 );
    printf("Reading from MRA generated ROM file. PCM starts at 0x%X (ends at 0x%X)\n", start, end);
    fseek( f, start+0x40, SEEK_SET );
    rdcnt = fread( rom, 1, end-start, f);
    if( rdcnt!= end-start ) {
        puts("Wrong MRA contents. Cannot read the full length of the ROM file");
        return NULL;
    }
    return rom;
}

char *read_ROM(FILE *f) {
    size_t rdcnt;
    char *rom = malloc( 4*64*1024 );
    rdcnt = fread( rom, 1, 4*64*1024, f );
    if( rdcnt < 8*128 ) {
        printf("Could not read the full header. Expecting 1024 bytes. Only %ld bytes read\n", rdcnt);
        free(rom);
        return NULL;
    }
    else return rom;
}

void dump( char *rom ) {
    int k;

    for( k=1; k<128; k++ ) {
        char fname[32];
        int start, end;
        FILE *fout;
        int aux=k<<3;
        start = ((((rom[aux+0] & 3) << 8) | (rom[aux+1]&0xff))<<8) | (rom[aux+2]&0xff);
        end   = ((((rom[aux+3] & 3) << 8) | (rom[aux+4]&0xff))<<8) | (rom[aux+5]&0xff);
        if( start > end ) {
            // printf("Warning: reverse order for sample 0x%x\n", k );
            continue;
        }
        if( start == end ) continue;
        sprintf(fname,"chunk_%x.bin",k);
        fout = fopen(fname,"wb");
        if( !fout ) {
            printf("Cannot create file %s\n", fname );
            return;
        }
        printf("%3d -> %6X to %6X\n", k, start, end );
        fwrite( rom+start, end-start, 1, fout );
        fclose(fout);
    }
}