#include <stdio.h>
#include <math.h>
#define FRAMES (16.0f-1.0f)
#define SLOWSPEED .0f
#define FASTSPEED 1.0f
#define SPEEDDIFF (float)FASTSPEED-SLOWSPEED
#define ROUND 64
float easeOut(float x);

int main(){
	FILE *file;
	file=fopen("output.s", "w");
		
	for (int i=0;i<=FRAMES;i++){
		float step = ((int)i) / FRAMES;
		//print the high byte of speed rounded down to .25
		int speed =  FASTSPEED-((round((((SPEEDDIFF)*easeOut(step))*ROUND)))/ROUND);
		if ((i & 0b111) == 0b000){
			fprintf(file,"\n\t.byte\t");
		}
		if ((i & 0b111) == 0b111){
			fprintf(file,"$%02X",speed);
		} else {
			fprintf(file,"$%02X, ",speed);
		
		}
	}
	for (int i=0;i<=FRAMES;i++){
		float step = ((int)i) / FRAMES;
		float speed =FASTSPEED-(round((((SPEEDDIFF)*easeOut(step))*ROUND))/ROUND);
		int whole =  FASTSPEED-((round((((SPEEDDIFF)*easeOut(step))*ROUND)))/ROUND);
		//print the low byte of speed rounded down to .5	
		if ((i & 0b111) == 0b000){
			fprintf(file,"\n\t.byte\t");
		}
		if ((i & 0b111) == 0b111){
			fprintf(file,"$%02X",(int)((speed-whole)*256));
		} else {
			fprintf(file,"$%02X, ",(int)((speed-whole)*256));
		}			
	}
}


float easeOut(float x){
	return x*x*x;

}

