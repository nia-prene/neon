#include <stdio.h>
#include <math.h>
#define FRAMES (16-1)
#define STEPS 1.0/FRAMES
#define SLOWSPEED .0f
#define FASTSPEED 4.0f
#define SPEEDDIFF (float)FASTSPEED-SLOWSPEED
#define ROUND 16
float easeOut(float x);

int main(){
	FILE *file;
	file=fopen("output.txt", "w");
		
	fprintf(file,"@playerSpeeds_H:\n");
	fprintf(file,"\t.byte ");

	for (float i=0;i<=1;i=i+STEPS){
		//print the high byte of speed rounded down to .25
		int speed =  FASTSPEED-((round((((SPEEDDIFF)*easeOut(i))*ROUND)))/ROUND);
		fprintf(file,"%2d, ",speed);
	}
	fprintf(file,"\n@playerSpeeds_L:\n");
	fprintf(file,"\t.byte ");
	for (float i=0;i<=1;i=i+STEPS){
		float speed =FASTSPEED-(round((((SPEEDDIFF)*easeOut(i))*ROUND))/ROUND);
		int whole =  FASTSPEED-((round((((SPEEDDIFF)*easeOut(i))*ROUND)))/ROUND);
		//print the low byte of speed rounded down to .5	
		fprintf(file,"%d, ",(int)((speed-whole)*256));
	}
}


float easeOut(float x){
	return x*x*x;

}

