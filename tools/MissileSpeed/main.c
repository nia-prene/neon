#include <stdio.h>
#include <math.h>
#define FRAMES (8-1)
#define STEPS 1.0/FRAMES
#define SLOWSPEED 0.0f
#define FASTSPEED 16.0f
#define SPEEDDIFF (float)FASTSPEED-SLOWSPEED
float easeIn(float x);

int main(){
	FILE *file;
	file=fopen("out.txt", "w");
		
	fprintf(file,"\t.byte ");

	for (float i=0;i<=1;i=i+STEPS){
		//print the high byte of speed rounded down to .5	
		int speed =  FASTSPEED-((round((((SPEEDDIFF)*easeIn(i))*2)))/2);
		fprintf(file,"%2d, ",speed);
	}
}


float easeIn(float x){
	return x * x  * x;

}

