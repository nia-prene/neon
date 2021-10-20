#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#define FILE_PATH "output.txt"
#define PI 3.14159265
int main(){
	
	FILE *outputFile;
	/*different radii to select from, cycles through list*/
	double xH;
	double xL;
	double yH;
	double yL;

	outputFile = fopen(FILE_PATH, "w");
	if (outputFile == NULL){
		printf("error opening file\n");
		return 1;
	}
	for (int i=0; i < 256; i++){
		if((i&0b1000000)==0){
			xL=(i&0b111111)*4;
			xH=(i&0b111111)*4+1;
			yL=(i&0b111111)*4+2;
			yH=(i&0b111111)*4+3;
		
		}else{
			yL=(i&0b111111)*4;
			yH=(i&0b111111)*4+1;
			xL=(i&0b111111)*4+2;
			xH=(i&0b111111)*4+3;
		
		}
		fprintf(outputFile, "bullet%02X:\n",i);	
		/*get the quadrant, my circles start in quadrant 3, not 1*/
		if(i < 256*.25){
			fprintf(outputFile, "\tbulletFib %d, ",3);	
		}else if(i < 256*.5){
			fprintf(outputFile, "\tbulletFib %d, ",4);	
		}else if(i < 256*.75){
			fprintf(outputFile, "\tbulletFib %d, ",1);	
		}else{
			fprintf(outputFile, "\tbulletFib %d, ",2);	
		}
		fprintf(outputFile, "%1.0f, %1.0f, %1.0f, %1.0f \n",xL, xH, yL, yH );
	}
	
	fclose(outputFile);
};
