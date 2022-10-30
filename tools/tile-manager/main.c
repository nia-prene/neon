#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>

typedef struct Tile{
//8 rows, two bytes each
	uint8_t bytes[16];
	uint8_t isUnique;
	int isActive;
}Tile;

typedef struct Metatile16{
	uint8_t topRight;
	uint8_t bottomRight;
	uint8_t topLeft;
	uint8_t bottomLeft;
	uint8_t isUnique;
	int isActive;
}Metatile16;

typedef struct Metatile32{
	uint8_t topRight;
	uint8_t bottomRight;
	uint8_t topLeft;
	uint8_t bottomLeft;
	uint8_t attribute;
	uint8_t isUnique;
	int isActive;
}Metatile32;

typedef struct Screen{
	uint8_t metatiles[64];
	int isActive;
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
	uint8_t palettes[16*16];
}Palettemap;

typedef struct CollectionBuffer{
//a screen CAN hold 256 16x16s (though unlikely)
	Metatile16 metatiles16[256];
//a screen CAN hold 64 32x32s (though unlikely)
	Metatile32 metatiles32[64];
//a screen CAN hold 256 tiles (though unlikely)
	Tile tiles[256];
	uint8_t remaps[256];
//screen tilemap
	Tilemap tilemap;
//16x16 palette squares
	Palettemap palettemap;
}CollectionBuffer;


FILE* openchr(int i);
FILE* openmap(int i);
FILE* openpal(int i);
void clearBuffer(CollectionBuffer *cb);
void addDefaultTiles(TileCollection *tc);
void readchr(CollectionBuffer *cb, FILE *chrin);
void readmap(CollectionBuffer *cb, FILE *mapin);
void readpal(CollectionBuffer *cb, FILE *palin);
void findRedundantChr(CollectionBuffer *cb, TileCollection *tc);
void insertUniqueChr(CollectionBuffer *cb, TileCollection *tc);
uint8_t insertChr(Tile *tile, TileCollection *collection);
void remapTilemap(CollectionBuffer *cb);
void to16(CollectionBuffer *cb);
void findRedundant16(CollectionBuffer *cb, TileCollection *tc);
void insertUnique16(CollectionBuffer *cb, TileCollection *tc);
uint8_t insert16(Metatile16 *tile, TileCollection *collection);
void to32(CollectionBuffer *cb);
void findRedundant32(CollectionBuffer *cb, TileCollection *tc);
void insertUnique32(CollectionBuffer *cb, TileCollection *tc);
uint8_t insert32(Metatile32 *tile, TileCollection *collection);
void insertScreen(CollectionBuffer *cb, TileCollection *tc);
void printChr(TileCollection *collection, FILE *chrout);
void print16(TileCollection *tc, FILE *out16);

int main(){
	FILE *chrin;
	FILE *mapin;
	FILE *palin;
	FILE *chrout;
	FILE *out16;

	TileCollection tileCollection={0};
	CollectionBuffer collectionBuffer={0};

	chrout = fopen("out/all.chr", "wb");
	if (chrout == NULL){
		printf("file out not valid");
		return 1;
	}
	out16= fopen("out/16.txt", "w");
	if (out16== NULL){
		printf("16 out not valid");
		return 1;
	}
	addDefaultTiles(&tileCollection);
	for(int i = 0; i<256; i++){
		chrin = openchr(i);
		if (!chrin)break;
		mapin = openmap(i);
		if (!mapin)break;
		palin = openpal(i);
		if (!palin)break;
		
		clearBuffer(&collectionBuffer);/*Clear buffer*/
		readchr(&collectionBuffer, chrin);
		readmap(&collectionBuffer, mapin);
		readpal(&collectionBuffer, palin);
		findRedundantChr(&collectionBuffer, &tileCollection);
		insertUniqueChr(&collectionBuffer, &tileCollection);
		remapTilemap(&collectionBuffer);
		to16(&collectionBuffer);
		findRedundant16(&collectionBuffer, &tileCollection);
		insertUnique16(&collectionBuffer, &tileCollection);
		to32(&collectionBuffer);
		findRedundant32(&collectionBuffer, &tileCollection);
		insertUnique32(&collectionBuffer, &tileCollection);
		insertScreen(&collectionBuffer, &tileCollection);
		fclose(chrin);
		fclose(mapin);
		fclose(palin);
	}
	printChr(&tileCollection, chrout);
	print16(&tileCollection, out16);
	
	fclose(chrout);
	fclose(out16);
	return 0;
}

void clearBuffer(CollectionBuffer *cb){
	for (int i = 0; i < 256; i++){
		cb -> tiles[i].isActive = 0;
	}
}

FILE* openchr(int i){
	char file[100] = "in/raw";
	char type[] = ".chr";
	char buf[10] = {};
	
	snprintf(buf, 10, "%02x", i);
	strcat (file, buf);
	strcat (file, type);

	printf("%s\n",file);
	FILE *chrin;
	chrin = fopen(file, "rb");
	return chrin;
}
FILE* openmap(int i){
	char file[100] = "in/tilemap";
	char type[] = ".bin";
	char buf[10] = {};
	
	snprintf(buf, 10, "%02x", i);
	strcat (file, buf);
	strcat (file, type);
	printf("%s\n",file);
	FILE *mapin;
	mapin = fopen(file, "rb");
	return mapin;
}
FILE* openpal(int i){
	char file[100] = "in/palettemap";
	char type[] = ".bin";
	char buf[10] = {};
	
	snprintf(buf, 10, "%02x", i);
	strcat (file, buf);
	strcat (file, type);
	printf("%s\n",file);
	FILE *palin;
	palin = fopen(file, "rb");
	return palin;
}

void addDefaultTiles(TileCollection *tc){
	Tile defaultTile;
//insert tile of all color zero
	insertChr(&defaultTile, tc);
//insert another tile of all color zero
	insertChr(&defaultTile, tc);
//insert tile of all color 1
	for(int i = 0; i < 8; i++){
		defaultTile.bytes[i]=255;	
	}
	insertChr(&defaultTile, tc);
//insert tile of all color 2
	for(int i = 0; i < 8; i++){
		defaultTile.bytes[i]=0;	
	}
	for(int i = 8; i <16; i++){
		defaultTile.bytes[i]=255;	
	}
	insertChr(&defaultTile, tc);
//insert tile of all color 3
	for(int i = 0; i < 8; i++){
		defaultTile.bytes[i]=255;	
	}
	insertChr(&defaultTile, tc);
}

void readchr(CollectionBuffer *cb, FILE *chrin){
//read the whole chrin file
	for (int i = 0; !(feof(chrin)); i++){
	//16 bytes (1 tile) at a time
		fread(cb -> tiles[i].bytes, 16, 1, chrin);
	//set it active
		cb -> tiles[i].isActive = 1;
	//set it unique
		cb -> tiles[i].isUnique = 1;
	}
}

void readmap(CollectionBuffer *cb, FILE *mapin){
	uint8_t buffer[4];
	fread(buffer, sizeof(buffer), 1, mapin);
	cb ->tilemap.header.width = buffer[3];
	fread(buffer, sizeof(buffer), 1, mapin);
	cb ->tilemap.header.height = buffer[3];
	fread(buffer, sizeof(buffer), 1, mapin);
	cb ->tilemap.header.mapWidth= buffer[3];
	fread(buffer, sizeof(buffer), 1, mapin);
	cb ->tilemap.header.mapHeight= buffer[3];
	for(int i =0; i < (32*32); i++){
		fread(buffer, sizeof(buffer), 1, mapin);
		cb ->tilemap.tiles[i] = buffer[3];
	}
}

void readpal(CollectionBuffer *cb, FILE *palin){
	uint8_t buffer[4];
	fread(buffer, sizeof(buffer), 1, palin);
	cb ->palettemap.header.width = buffer[3];
	fread(buffer, sizeof(buffer), 1, palin);
	cb ->palettemap.header.height = buffer[3];
	fread(buffer, sizeof(buffer), 1, palin);
	cb ->palettemap.header.mapWidth= buffer[3];
	fread(buffer, sizeof(buffer), 1, palin);
	cb ->palettemap.header.mapHeight= buffer[3];
	for(int i =0; i < (16*16); i++){
		fread(buffer, sizeof(buffer), 1, palin);
		cb ->palettemap.palettes[i] = buffer[3];
	}
}

void findRedundantChr(CollectionBuffer *cb, TileCollection *tc){
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
void insertUniqueChr(CollectionBuffer *cb, TileCollection *tc){
	for (int i = 0; i < 256; i++){
		if(cb -> tiles[i].isUnique){
			cb ->remaps[i] = insertChr(&(cb -> tiles[i]), tc);
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

uint8_t insertChr(Tile *tile, TileCollection *collection){
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

void remapTilemap(CollectionBuffer *cb){
//for every mapped tile
	for(int i=0; i<(32*32);i++){
	//replace with the remap equivelant
		cb->tilemap.tiles[i]=cb->remaps[cb->tilemap.tiles[i]];
	}
}

void to16(CollectionBuffer *cb){
	int i = 0;
//16 rows
	for (int j = 0; j < 16; j++){
	//16 columns
		for (int k = 0; k < 16; k++){
			cb -> metatiles16[(j*16)+k].topLeft = cb -> tilemap.tiles[i];
			i++;
			cb -> metatiles16[(j*16)+k].topRight = cb -> tilemap.tiles[i];
			i++;
		}
		for (int k = 0; k < 16; k++){
			cb -> metatiles16[(j*16)+k].bottomLeft = cb -> tilemap.tiles[i];
			i++;
			cb -> metatiles16[(j*16)+k].bottomRight = cb -> tilemap.tiles[i];
			i++;
			cb -> metatiles16[(j*16)+k].isActive = 1;
			cb -> metatiles16[(j*16)+k].isUnique = 1;

		}
	}
}
void findRedundant16(CollectionBuffer *cb, TileCollection *tc){
	for(int i = 0; i < 256; i++){
		if(cb -> metatiles16[i].isActive){
			for(int j = 0; j < 256; j++){
				if(tc -> metatiles16[j].isActive){
					if(!memcmp(&(cb->metatiles16[i]), &(tc->metatiles16[j]), sizeof(cb->metatiles16[i]))){
						cb -> remaps[i] = j;
						cb -> metatiles16[i].isUnique = 0;
					}
				}
			}
		}
	}
	for (int i = 0; i < 256; i++){
		if((cb -> metatiles16[i].isActive) &&(cb -> metatiles16[i].isUnique)){
			for(int j = i+1; j < 256; j++){
				if((cb -> metatiles16[j].isActive)&&(cb -> metatiles16[j].isUnique)){
					if(!memcmp(&(cb->metatiles16[i]), &(cb->metatiles16[j]), sizeof(cb->metatiles16[i]))){
						cb -> remaps[j] = i;
						cb -> metatiles16[j].isUnique = 0;
					}	
				}
			}
		}
	}
}
void insertUnique16(CollectionBuffer *cb, TileCollection *tc){
	for (int i = 0; i < 256; i++){
		if((cb -> metatiles16[i].isActive) &&(cb -> metatiles16[i].isUnique)){
			cb -> remaps[i]=insert16(&(cb->metatiles16[i]),tc);
		}
	}
	for (int i = 0; i < 256; i++){
		if((cb -> metatiles16[i].isActive) &&(!cb -> metatiles16[i].isUnique)){
			cb -> remaps[i]=cb ->remaps[cb ->remaps[i]];
		}
	}
}
uint8_t insert16(Metatile16 *tile, TileCollection *collection){
	for(int i=0; i<256; i++){
		if(!collection->metatiles16[i].isActive){
			collection->metatiles16[i].topLeft = tile->topLeft;
			collection->metatiles16[i].topRight= tile->topRight;
			collection->metatiles16[i].bottomLeft= tile->bottomLeft;
			collection->metatiles16[i].bottomRight= tile->bottomRight;
			collection->metatiles16[i].isActive = 1;
			return i;
		}
	}
	printf("collection full");
	return 0; 
}

void to32(CollectionBuffer *cb){
	int i = 0;
//8 rows
	for (int j = 0; j < 8; j++){
	//8 columns
		for (int k = 0; k < 8; k++){
			cb->metatiles32[(j*8)+k].topLeft = cb->remaps[i];
			cb->metatiles32[(j*8)+k].attribute= cb->palettemap.palettes[i];
			i++;
			cb->metatiles32[(j*8)+k].topRight = cb->remaps[i];
			cb->metatiles32[(j*8)+k].attribute= (cb->metatiles32[(j*8)+k].attribute)|((cb->palettemap.palettes[i])<<2);
			i++;
		}
		for (int k = 0; k < 8; k++){
			cb->metatiles32[(j*8)+k].bottomLeft = cb->remaps[i];
			cb->metatiles32[(j*8)+k].attribute= (cb->metatiles32[(j*8)+k].attribute)|((cb->palettemap.palettes[i])<<4);
			i++;
			cb->metatiles32[(j*8)+k].bottomRight = cb->remaps[i];
			cb->metatiles32[(j*8)+k].attribute= (cb->metatiles32[(j*8)+k].attribute)|((cb->palettemap.palettes[i])<<6);
			i++;
			cb -> metatiles32[(j*8)+k].isActive = 1;
			cb -> metatiles32[(j*8)+k].isUnique = 1;
		}
	}
}
void findRedundant32(CollectionBuffer *cb, TileCollection *tc){
	for(int i = 0; i < 64; i++){
		if(cb -> metatiles32[i].isActive){
			for(int j = 0; j < 256; j++){
				if(tc -> metatiles32[j].isActive){
					if(!memcmp(&(cb->metatiles32[i]), &(tc->metatiles32[j]), sizeof(cb->metatiles32[i]))){
						cb -> remaps[i] = j;
						cb -> metatiles32[i].isUnique = 0;
					}
				}
			}
		}
	}
	for (int i = 0; i < 64; i++){
		if((cb -> metatiles32[i].isActive) &&(cb -> metatiles32[i].isUnique)){
			for(int j = i+1; j < 64; j++){
				if((cb -> metatiles32[j].isActive)&&(cb -> metatiles32[j].isUnique)){
					if(!memcmp(&(cb->metatiles32[i]), &(cb->metatiles32[j]), sizeof(cb->metatiles32[i]))){
						cb -> remaps[j] = i;
						cb -> metatiles32[j].isUnique = 0;
					}	
				}
			}
		}
	}
}
void insertUnique32(CollectionBuffer *cb, TileCollection *tc){
	for (int i = 0; i < 64; i++){
		if((cb -> metatiles32[i].isActive) &&(cb -> metatiles32[i].isUnique)){
			cb -> remaps[i]=insert32(&(cb->metatiles32[i]),tc);
		}
	}
	for (int i = 0; i < 64; i++){
		if((cb -> metatiles32[i].isActive) &&(!cb -> metatiles32[i].isUnique)){
			cb->remaps[i]=cb->remaps[cb->remaps[i]];
		}
	}
}
uint8_t insert32(Metatile32 *tile, TileCollection *collection){
	for(uint8_t i=0; i<256; i++){
		if(!collection->metatiles32[i].isActive){
			collection->metatiles32[i].topLeft=tile->topLeft;
			collection->metatiles32[i].topRight=tile->topRight;
			collection->metatiles32[i].bottomLeft=tile->bottomLeft;
			collection->metatiles32[i].bottomRight=tile->bottomRight;
			collection->metatiles32[i].attribute=tile->attribute;
			collection->metatiles32[i].isActive = 1;
			return i;
		}
	}
	printf("collection full");
	return 0; 
}
void insertScreen(CollectionBuffer *cb, TileCollection *tc){
	for(int i=0;i<256;i++){
		if(!tc->screens[i].isActive){	
			for(int j=0;j<64;j++){
				tc->screens[i].metatiles[j]=cb->remaps[j];
			}
			tc->screens[i].isActive=1;
			return;
		}
	}
}
void print16(TileCollection *tc, FILE *out16){
	for(int i=0; i<256; i++){
		if(tc->screens[i].isActive){
			fprintf(out16,"\nscreen%.2x:\n\t.byte ",i);
			for(int j =0;j<64;j++){
				fprintf(out16,"$%.2x, ",tc->screens[i].metatiles[j]);
			}		
		}
	}
	fprintf(out16,"\ntopLeft32:\n\t.byte ");
	for(int i=0; i<256; i++){
		if(tc->metatiles32[i].isActive){
			fprintf(out16,"$%.2x, ",tc->metatiles32[i].topLeft);
		}
	}
	fprintf(out16,"\ntopRight32:\n\t.byte ");
	for(int i=0; i<256; i++){
		if(tc->metatiles32[i].isActive){
			fprintf(out16,"$%.2x, ",tc->metatiles32[i].topRight);
		}
	}
	fprintf(out16,"\nbottomLeft32:\n\t.byte ");
	for(int i=0; i<256; i++){
		if(tc->metatiles32[i].isActive){
			fprintf(out16,"$%.2x, ",tc->metatiles32[i].bottomLeft);
		}
	}
	fprintf(out16,"\nbottomRight32:\n\t.byte ");
	for(int i=0; i<256; i++){
		if(tc->metatiles32[i].isActive){
			fprintf(out16,"$%.2x, ",tc->metatiles32[i].bottomRight);
		}
	}
	fprintf(out16,"\ntileAttributeByte:\n\t.byte ");
	for(int i=0; i<256; i++){
		if(tc->metatiles32[i].isActive){
			fprintf(out16,"$%.2x, ",tc->metatiles32[i].attribute);
		}
	}
	fprintf(out16,"\ntopLeft16:\n\t.byte ");
	for(int i=0; i<256; i++){
		if(tc->metatiles16[i].isActive){
			fprintf(out16,"$%.2x, ",tc->metatiles16[i].topLeft);
		}
	}
	fprintf(out16,"\ntopRight16:\n\t.byte ");
	for(int i=0; i<256; i++){
		if(tc->metatiles16[i].isActive){
			fprintf(out16,"$%.2x, ",tc->metatiles16[i].topRight);
		}
	}
	fprintf(out16,"\nbottomLeft16:\n\t.byte ");
	for(int i=0; i<256; i++){
		if(tc->metatiles16[i].isActive){
			fprintf(out16,"$%.2x, ",tc->metatiles16[i].bottomLeft);
		}
	}
	fprintf(out16,"\nbottomRight16:\n\t.byte ");
	for(int i=0; i<256; i++){
		if(tc->metatiles16[i].isActive){
			fprintf(out16,"$%.2x, ",tc->metatiles16[i].bottomRight);
		}
	}
}
