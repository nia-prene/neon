#include <stdio.h>
#include <math.h>
#define FRAMES (16-1)
#define STEPS 1.0/FRAMES
#define SLOWSPEED .3515625f
#define FASTSPEED (round(1.0585f*8)/8)
#define SPEEDDIFF (float)FASTSPEED-SLOWSPEED
#define ROUND 16
float easeIn(float x);

int main(){
	FILE *file;
	file=fopen("output.txt", "w");
		
	fprintf(file,"@playerSpeeds_H:\n");
	fprintf(file,"\t.byte ");

	for (float i=1;i>=0;i=i-STEPS){
		//print the high byte of speed rounded down to .25
		int speed =  FASTSPEED-((round((((SPEEDDIFF)*easeIn(i))*ROUND)))/ROUND);
		fprintf(file,"%2d, ",speed);
	}
	fprintf(file,"\n@playerSpeeds_L:\n");
	fprintf(file,"\t.byte ");
	for (float i=1;i>=0;i=i-STEPS){
		float speed =FASTSPEED-(round((((SPEEDDIFF)*easeIn(i))*ROUND))/ROUND);
		int whole =  FASTSPEED-((round((((SPEEDDIFF)*easeIn(i))*ROUND)))/ROUND);
		//print the low byte of speed rounded down to .5	
		fprintf(file,"%d, ",(int)((speed-whole)*256));
	}
}


float easeIn(float x){
	return x * x * x;

}

