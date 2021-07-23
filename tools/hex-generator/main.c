#include <stdio.h>
#include <stdlib.h>
#define FILE_PATH "output.txt"
#define STARTING_BYTE 0
#define INCREMENT 0
#define LENGTH_IN_BYTES 32
int main(){
	
	FILE *outputFile;
	int hexDigit = 0;
	int i;
	char wordByte[] = ".byte ";
	char *word = wordByte;

	outputFile = fopen(FILE_PATH, "w");
	if (outputFile == NULL){
		printf("error opening file\n");
		return 1;
	}
	fprintf(outputFile, "\t%s", word);
	for(hexDigit = STARTING_BYTE , i = 1; i <= LENGTH_IN_BYTES; hexDigit = hexDigit+INCREMENT, i++){
		if(hexDigit > 255){
			hexDigit = 255;
		}
		if((i > 2) && (i % 16 == 0)){
			fprintf(outputFile, "$%2.2x\n", hexDigit);
			fprintf(outputFile, "\t%s", word);
		}else{
			fprintf(outputFile, "$%2.2x, ", hexDigit);
		}
	}
	fclose(outputFile);
};
