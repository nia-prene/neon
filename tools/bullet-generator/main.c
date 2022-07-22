#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#define FILE_PATH "output.txt"
#define PI 3.14159265
int main(){
	
	FILE *outputFile;
	/*different radii to select from, cycles through list*/
	double radii[4]={2, 2.5, 2, 3};
	double segments = 256;
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
	for (i = 0; i <256; i++){
		/*calculate degrees per segment*/
		degrees = (360/segments)*i;
		/*y = r sin(radons) selects radius from list using 2 MSB of i*/
		y = fabs(radii[i&0b11]*sin(degrees*PI/180));
		/*x = r cos(radons) selects radius from list using 2 MSB of i*/
		x = fabs(radii[i&0b11]*cos(degrees*PI/180));
		/*separate whole number from decimal*/
		xH = floor(x);
		yH = floor(y);
		xL = x-xH;
		yL = y-yH;
		/*change decimal into hex-based number (rounding down to ensure within range*/
		xL = floor(xL*256);
		yL = floor(yL*256);
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
		fprintf(outputFile, "#%1.0f, #%1.0f, #%1.0f, #%1.0f \n",xH, xL, yH, yL );
	}
	fclose(outputFile);
};
