#include <stdio.h>
#include <stdint.h>
#include <string.h>

typedef struct Tile{
//8 rows, two bytes each
	uint8_t bytes[16];
	uint8_t isActive;
	uint8_t isUnique;
	uint8_t id ;
}Tile;

typedef struct Metatile16{
	uint8_t topRight;
	uint8_t bottomRight;
	uint8_t topLeft;
	uint8_t bottomLeft;
	uint8_t id;
	uint8_t isUnique;
}Metatile16;

typedef struct Metatile32{
	uint8_t topRight;
	uint8_t bottomRight;
	uint8_t topLeft;
	uint8_t bottomLeft;
	uint8_t palette;
	uint8_t id;
	uint8_t isUnique;
}Metatile32;

typedef struct Screen{
	uint8_t metatiles[64];
	uint8_t id;
}Screen;

typedef struct TileCollection{
//the totality of the games tiles
	Screen screens[256];
	Metatile32 metatiles32[256];
	Metatile16 metatiles16[256];
	Tile tiles[256];
}TileCollection;

typedef struct Header{
	uint8_t width;
	uint8_t height;
	uint8_t mapWidth;
	uint8_t mapHeight;
}Header;

typedef struct Tilemap{
	Header header;
	//32 rows of 32 columns
	uint8_t tiles[32*32];
}Tilemap;

typedef struct Palettemap{
	Header header;
	//16 rows of 16 columns
	uint8_t tiles[16*16];
}Palettemap;

typedef struct CollectionBuffer{
//a screen CAN hold 356 16x16s (though unlikely)
	Metatile16 metatiles16[256];
//a screen CAN hold 64 32x32s (though unlikely)
	Metatile32 metatiles32[64];
//a screen CAN hold 256 tiles (though unlikely)
	Tile tiles[256];
	uint8_t remaps[256];
//32 rows and 32 columns of 8x8 tiles
	uint8_t tilemap[32*32];
//16x16 palette squares
	uint8_t palettemap[256];
}CollectionBuffer;


void clearBuffer(CollectionBuffer *cb);
void addDefaultTiles(TileCollection *tc);
void readchr(CollectionBuffer *cb, FILE *chrin);
void findRedundant(CollectionBuffer *cb, TileCollection *tc);
void insertUnique(CollectionBuffer *cb, TileCollection *tc);
void printChr(TileCollection *cb, FILE *chrout);
uint8_t insertTile(Tile *tile, TileCollection *collection);

int main(){
	FILE *chrin;
	FILE *intile;
	FILE *inpalette;
	FILE *chrout;
	TileCollection tileCollection={0};
	CollectionBuffer collectionBuffer={0};

	chrin = fopen("in/raw00.chr", "rb");
	if (chrin == NULL){
		printf("file not valid");
		return 1;
	}
	chrout = fopen("out/all.chr", "wb");
	if (chrin == NULL){
		printf("file out not valid");
		return 1;
	}
	addDefaultTiles(&tileCollection);
	readchr(&collectionBuffer, chrin);
	findRedundant(&collectionBuffer, &tileCollection);
	insertUnique(&collectionBuffer, &tileCollection);
	printChr(&tileCollection, chrout);

	fclose(chrin);
	fclose(chrout);
	return 0;
}

void clearBuffer(CollectionBuffer *cb){
	for (int i = 0; i < 256; i++){
		cb -> tiles[i].isActive = 0;
	}
}

void addDefaultTiles(TileCollection *tc){
	Tile defaultTile;
//insert tile of all color zero
	insertTile(&defaultTile, tc);
//insert another tile of all color zero
	insertTile(&defaultTile, tc);
//insert tile of all color 1
	for(int i = 0; i < 8; i++){
		defaultTile.bytes[i]=255;	
	}
	insertTile(&defaultTile, tc);
//insert tile of all color 2
	for(int i = 0; i < 8; i++){
		defaultTile.bytes[i]=0;	
	}
	for(int i = 8; i <16; i++){
		defaultTile.bytes[i]=255;	
	}
	insertTile(&defaultTile, tc);
//insert tile of all color 3
	for(int i = 0; i < 8; i++){
		defaultTile.bytes[i]=255;	
	}
	insertTile(&defaultTile, tc);
}

void readchr(CollectionBuffer *cb, FILE *chrin){
//read the whole chrin file
	for (int i = 0; !(feof(chrin)); i++){
	//16 bytes (1 tile) at a time
		fread(cb -> tiles[i].bytes, 16, 1, chrin);
	//the ID is read in order, this corresponds to the tilemap
		cb -> tiles[i].id = i;
	//set it active
		cb -> tiles[i].isActive = 1;
	//set it unique
		cb -> tiles[i].isUnique = 1;
	}
}

void findRedundant(CollectionBuffer *cb, TileCollection *tc){
	for(int i = 0; i<256; i++){
		if(cb->tiles[i].isActive){
			for(int j = 1; j<256; j++){
				if(tc->tiles[j].isActive){
					if(!memcmp(tc->tiles[j].bytes, cb->tiles[i].bytes, sizeof(cb->tiles[i].bytes))){
						cb->tiles[i].isUnique=0;	
						cb->remaps[i]=j;	
					}
				}	
			}
		}
	}
}
void insertUnique(CollectionBuffer *cb, TileCollection *tc){
	for (int i = 0; i < 256; i++){
		if(cb -> tiles[i].isUnique){
			cb ->remaps[i] = insertTile(&(cb -> tiles[i]), tc);
		}
	}
}
void printChr(TileCollection *collection, FILE *chrout){
	for (int i = 0; i < 256; i++){
		if(collection-> tiles[i].isActive){
			fwrite(collection-> tiles[i].bytes, 16, 1, chrout);
		}
	}
}

uint8_t insertTile(Tile *tile, TileCollection *collection){
	for(uint8_t i=0; i<256; i++){
		if(!collection->tiles[i].isActive){
			memcpy(collection->tiles[i].bytes, tile->bytes, sizeof(tile->bytes));
			collection->tiles[i].isActive = 1;
			return i;
		}
	}
	printf("collection full");
	return 0; 
}
