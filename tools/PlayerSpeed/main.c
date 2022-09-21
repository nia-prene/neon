#include <stdio.h>
#include <math.h>
#define FRAMES 16
#define STEPS 1.0/FRAMES
#define SLOWSPEED .234375
//#define SLOWSPEED .5
#define FASTSPEED 1.0625f
//#define FASTSPEED 1.5
#define SPEEDDIFF (float)FASTSPEED-SLOWSPEED

float easeIn(float x);

int main(){
	FILE *file;
	file=fopen("output.txt", "w");
		
	fprintf(file,"@playerSpeeds_H:\n");
	fprintf(file,"\t.byte ");

	for (float i=1;i>=STEPS;i=i-STEPS){
		//print the high byte of speed rounded down to .25
		int speed =  FASTSPEED-((floor((((SPEEDDIFF)*easeIn(i))*4)))/4);
		fprintf(file,"%2d, ",speed);
	}
	fprintf(file,"\n@playerSpeeds_L:\n");
	fprintf(file,"\t.byte ");
	for (float i=1;i>=STEPS;i=i-STEPS){
		float speed =FASTSPEED-(floor((((SPEEDDIFF)*easeIn(i))*4))/4);
		int whole =  FASTSPEED-((floor((((SPEEDDIFF)*easeIn(i))*4)))/4);
		//print the low byte of speed rounded down to .5	
		fprintf(file,"%d, ",(int)((speed-whole)*256));
	}
}


float easeIn(float x){
	return x * x * x;

}

