#include <stdio.h>
#include <math.h>
#define FRAMES (16-1)
#define STEPS 1.0/FRAMES
#define SLOWSPEED 0
#define FASTSPEED 1
#define SPEEDDIFF (float)FASTSPEED-SLOWSPEED
#define ROUND 64
float easeIn(float x);

int main(){
	FILE *file;
	file=fopen("output.s", "w");
		
	for (int i=0;i<=FRAMES;i=i+1){
		//print the high byte of speed rounded down to .25
		float step = ((float)i)/FRAMES;
		int speed =  SLOWSPEED+((round((((SPEEDDIFF)*easeIn(step))*ROUND)))/ROUND);
		if ((i & 0b111) == (0b000)){
			fprintf(file,"\n\t.byte\t");
		}
		if ((i & 0b111) == (0b111)){
			fprintf(file,"$%02X",speed);
		}else {
			fprintf(file,"$%02X ,",speed);
		}
	}
	fprintf(file,"\n");
	for (int i=0;i<=FRAMES;i=i+1){
		float step = ((float)i)/FRAMES;
		float speed =SLOWSPEED+(round((((SPEEDDIFF)*easeIn(step))*ROUND))/ROUND);
		int whole =  SLOWSPEED+((round((((SPEEDDIFF)*easeIn(step))*ROUND)))/ROUND);
		//print the low byte of speed rounded down to .5	
		if ((i & 0b111) == (0b000)){
			fprintf(file,"\n\t.byte\t");
		}
		if ((i & 0b111) == (0b111)){
			fprintf(file,"$%02X",(int)((speed-whole)*256));
		} else {
			fprintf(file,"$%02X, ",(int)((speed-whole)*256));
		}
	}
}


float easeIn(float x){
	return x * x * x ;

}

