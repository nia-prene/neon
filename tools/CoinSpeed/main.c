#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define FILE_PATH "output.txt"
#define SPEED_LO 0
#define SPEED_HI 12

float ease(float x);

int main(){
	
	FILE *outputFile;
	int hiByte;
	int loByte;
	float temp;

	outputFile = fopen(FILE_PATH, "w");
	if (outputFile == NULL){
		printf("error opening file\n");
		return 1;
	}

	fprintf(outputFile, "\nCoin_speed_L:");

	for(int i = 0; i < 256; i++){
		if (!(i & 0b1111)){
			fprintf(outputFile, "\n\t.byte ");
		}	
		temp = ((SPEED_HI - SPEED_LO) * (ease((float)i / 256))) + SPEED_LO;
		hiByte= floor(temp);
		loByte = (temp - hiByte) * 256;
		if ((i & 0b1111) == 0b1111){
			fprintf(outputFile, "%3d", loByte);
		}else{
			fprintf(outputFile, "%3d, ", loByte);
		}
	}
	fprintf(outputFile, "\nCoin_speed_H:");

	for(int i = 0; i < 256; i++){
		//every 16 bytes print a new line
		if (!(i & 0b1111)){
			fprintf(outputFile, "\n\t.byte ");
		}	
		temp = ((SPEED_HI - SPEED_LO) * (ease((float)i / 256))) + SPEED_LO;
		hiByte= floor(temp);
		if ((i & 0b1111) == 0b1111){
			fprintf(outputFile, "%3d", hiByte);
		}else{
			fprintf(outputFile, "%3d, ", hiByte);
		}
	}
	fclose(outputFile);
};

float ease(float x){
	return x == 1 ? 1 : 1 - pow(2, -10 * x);
}
