#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#define FILE_PATH "output.txt"
#define RADIUS  4
#define SEGMENTS  64
#define STARTING_BULLET 192
#define PI 3.14159265
int main(){
	
	FILE *outputFile;
	double x;
	double xH;
	double xL;
	double y;
	double yH;
	double yL;
	double segments = SEGMENTS;
	int i;
	double degrees;

	outputFile = fopen(FILE_PATH, "w");
	if (outputFile == NULL){
		printf("error opening file\n");
		return 1;
	}
	for (i = 0; i <SEGMENTS; i++){
		/*calculate degrees per segment*/
		degrees = (360/segments)*i;
		/*x = r sin(radons)*/
		x = fabs(RADIUS*sin(degrees*PI/180));
		/*y = r cos(radons)*/
		y = fabs(RADIUS*cos(degrees*PI/180));
		/*separate whole number from decimal*/
		xH = floor(x);
		yH = floor(y);
		xL = x-xH;
		yL = y-yH;
		/*change decimal into hex-based number*/
		xL = round(xL*256);
		yL = round(yL*256);
			fprintf(outputFile, "bullet%02X:\n",STARTING_BULLET+i);	
		/*get the quadrant, my circles start in quadrant 3, not 1*/
		if(i < SEGMENTS*.25){
			fprintf(outputFile, "\tmainFib %d, ",3);	
		}else if(i < SEGMENTS*.5){
			fprintf(outputFile, "\tmainFib %d, ",4);	
		}else if(i < SEGMENTS*.75){
			fprintf(outputFile, "\tmainFib %d, ",1);	
		}else{
			fprintf(outputFile, "\tmainFib %d, ",2);	
		}
		/*x and y values are swapped when printing. this is because 0 degrees on my circles start at 90 degrees to the left and goes counterclockwise*/
		fprintf(outputFile, "#%1.0f, #%1.0f, #%1.0f, #%1.0f \n",yH, yL, xH, xL );
	}
	fclose(outputFile);
};
