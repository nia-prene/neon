#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#define FILE_PATH "output.txt"
#define PI 3.14159265
#define SPEEDS 8
#define SEGMENTS 256.0f

int main(){
	
	FILE *outputFile;
	/*different radii to select from, cycles through list*/
	double radii[]={1.50,1.75,2.00,2.25,2.50,2.75,3.0,3.25,};
	/*64 different angles*/
	double x;
	double xH;
	double xL;
	double y;
	double yH;
	double yL;
	int i;
	double degrees;

	outputFile = fopen(FILE_PATH, "w");
	if (outputFile == NULL){
		printf("error opening file\n");
		return 1;
	}
	for (i = 0; i < 256; i++){
		/*calculate degrees per segment, 1 for each speed*/
		degrees = (360/SEGMENTS)*(i);
		/*y = r sin(radons) selects radius from list using 2 MSB of i*/
		y = fabs(radii[i&0b111]*sin(degrees*PI/180));
		/*x = r cos(radons) selects radius from list using 2 MSB of i*/
		x = fabs(radii[i&0b111]*cos(degrees*PI/180));
		/*separate whole number from decimal*/
		xH = floor(x);
		yH = floor(y);
		xL = x-xH;
		yL = y-yH;
		/*change decimal into hex-based number*/ 
		xL = floor(xL*256);
		yL = floor(yL*256);
		/*print label*/
			fprintf(outputFile, "\nbullet%02X:\n",i);	
		/*get the quadrant*/
		if(i < 64){
			fprintf(outputFile, "\tbulletFib %d, ",3);	
		}else if(i < 128){
			fprintf(outputFile, "\tbulletFib %d, ",4);	
		}else if(i < 192){
			fprintf(outputFile, "\tbulletFib %d, ",1);	
		}else if(i < 256){
			fprintf(outputFile, "\tbulletFib %d, ",2);	
		}
		fprintf(outputFile, "#%1.0f, #%1.0f, #%1.0f, #%1.0f",xH, xL, yH, yL );
	}
	fclose(outputFile);
};
