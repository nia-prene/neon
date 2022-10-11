#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#define FILE_PATH "output.txt"
#define PI 3.14159265
#define DIRECTIONS 8
#define SPEED 0.75f

int main(){
	
	FILE *outputFile;
	/*different radii to select from, cycles through list*/
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
	for (i = 0; i < DIRECTIONS; i++){
		/*calculate degrees per segment, 1 for each speed*/
		degrees = (360/DIRECTIONS)*(i);
		/*y = r sin(radons) selects radius from list using 2 MSB of i*/
		y = fabs(SPEED*sin(degrees*PI/180));
		/*x = r cos(radons) selects radius from list using 2 MSB of i*/
		x = fabs(SPEED*cos(degrees*PI/180));
		/*separate whole number from decimal*/
		xH = floor(x);
		yH = floor(y);
		xL = x-xH;
		yL = y-yH;
		/*change decimal into hex-based number*/ 
		xL = floor(xL*256);
		yL = floor(yL*256);
		/*print label*/
		fprintf(outputFile, "#%1.0f, #%1.0f, #%1.0f, #%1.0f\n",xH, xL, yH, yL );
	}
	fclose(outputFile);
};
