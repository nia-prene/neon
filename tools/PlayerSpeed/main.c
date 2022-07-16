#include <stdio.h>
#include <math.h>
#define FRAMES 32 
#define STEPS 1.0/FRAMES
#define SLOWSPEED .5f
#define FASTSPEED 2.0f
#define SPEEDDIFF (float)FASTSPEED-SLOWSPEED

float easeIn(float x);

int main(){
	FILE *file;
	file=fopen("speed.txt", "w");
		
	fprintf(file,"@playerSpeeds_H:\n");
	fprintf(file,"\t.byte ");

	for (float i=0;i<=1;i=i+STEPS){
		//print the high byte of speed rounded down to .5	
		int speed =  FASTSPEED-((floor((((SPEEDDIFF)*easeIn(i))*2)))/2);
		fprintf(file,"%2d, ",speed);
	}
	fprintf(file,"\n@playerSpeeds_L:\n");
	fprintf(file,"\t.byte ");
	for (float i=0;i<=1;i=i+STEPS){
		float speed =FASTSPEED-((floor((((SPEEDDIFF)*easeIn(i))*2)))/2);
		int whole =  FASTSPEED-((floor((((SPEEDDIFF)*easeIn(i))*2)))/2);
		//print the low byte of speed rounded down to .5	
		fprintf(file,"%d, ",(int)((speed-whole)*256));
	}
}


float easeIn(float x){
	return x * x * x;

}

