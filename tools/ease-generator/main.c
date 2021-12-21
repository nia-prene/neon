#include <stdio.h>
#include <math.h>
#define FRAMES 32 
#define DISTANCE 88
#define STEPS 1.0/FRAMES
#define START 238

float easeOut(float p);

int main(){
	FILE *file;
	file=fopen("ease-lut.txt", "w");
		
	fprintf(file,".byte ");

	for (float i=0;i<1;i=i+STEPS){
		fprintf(file,"%.2d, ",START - (int)ceil(DISTANCE * easeOut(i)));

	}
}


float easeOut(float p)
{
	return (p == 1.0) ? p : 1 - pow(2, -10 * p);
}
