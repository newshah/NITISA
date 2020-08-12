#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include <time.h>
#include <string.h>


// Code should be called like this : ./programfr100.o ds_500.txt 500
int main(int argc, char **argv)
{

    uint32_t max_rate = 1000;
    float temp = 0;
    uint16_t fr_ref[256] = {0};
    float fr = 0;
    int numberOfSpikes = 0;
    int numberOfSpikesPerImage = 0;
    int i,j,k;
    int imageCounter = 1;
    char* filename = "";

    char* rawText;
    
    char* pixels;

    int numberOfData = 0;

    uint8_t spikeMat [784][1000] = {0};
        
//    rawText = (char *) malloc((numberOfData * 784 * 2) + 100);
    
    for (i = 0; i< 256; i++){
        fr_ref[i] = (int)((max_rate / 256.0) * i);
    }
    
    if(argc == 0){
	printf("Error in input file. \n");
        return 0;
	}
    else
    {
	printf("Here!\n");
        filename = argv[1];
        numberOfData = atoi(argv[2]);
	printf("filename is : %s, and number of digits: %d\n", filename, numberOfData);
        FILE * dataset;
        dataset = fopen(filename, "r");
	if(dataset == NULL){
		printf("File does not exist!\n");
	return 0;
	}
	rawText = (char *) malloc((numberOfData * 784 * 2) + 100);
	printf("Here2!\n");
        fgets(rawText,(numberOfData * 784 * 2) + 100,dataset);
	//printf("Data is:%s\n",rawText);
        pixels = strtok(rawText,",");
        int count = 0;
	printf("AMHM: Real execution starts\n");

        while (pixels!= NULL)
        {
            //printf ("%s\n",pixels);
            int pixel_val = atoi(pixels);
            pixels = strtok (NULL, ",");

            if(count < (numberOfData * 784) - 2 )
                count ++;

            if(pixel_val == 256)
                fr = fr_ref[pixel_val];
            else
                fr = fr_ref[pixel_val + 1];

            srand((unsigned) time(NULL));

            for(k = 0; k < 1000; k++){
                temp = ((rand()%100)/100.0);
                //printf("random number: %.5f. fire rate to dt = %d\n", temp,fr);
                if (temp < fr*0.001){

                    spikeMat[count % 784][k] = 1;
                    numberOfSpikes += 1;
                    numberOfSpikesPerImage += 1;
                    //printf("for_if_1\n");

                }
                else
                {
                   spikeMat[count % 784][k] = 0;
                    //printf("for_if_2\n");
                }
           
            } 

            if(count % 784 == 0)
            {
                imageCounter += 1;
                //printf("Spike train for Image %d. Number of spikes %d\n", imageCounter, numberOfSpikesPerImage);
                numberOfSpikesPerImage = 0;

            }
        }

            
    }
    
	

	printf("Spike train generation finished. Total Number of spikes %d\n", numberOfSpikes);
	return 0;
}
