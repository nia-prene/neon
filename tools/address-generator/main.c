#include <stdio.h>
#include <stdlib.h>
#define FILE_PATH "output.txt"
#define ADDRESS_COUNT 256
int main(){
	
	char arrayName[] = "romEnemyBulletBehavior";
	char objectName[] = "bullet";
	FILE *outputFile;
	int i;

	outputFile = fopen(FILE_PATH, "w");
	if (outputFile == NULL){
		printf("error opening file\n");
		return 1;
	}
	fprintf(outputFile, "%sH:\n",arrayName);	
	for (i = 0; i < ADDRESS_COUNT; i++){
		fprintf(outputFile, "\t.byte >(%s%02X)\n", objectName, i);
	}
	fprintf(outputFile, "%sL:\n",arrayName);	
	for (i = 0; i < ADDRESS_COUNT; i++){
		fprintf(outputFile, "\t.byte <(%s%02X)\n", objectName, i);
	}
	fclose(outputFile);
};
