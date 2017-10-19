/*
 
 -Course-
 DAT300: Data-driven support for cyber-physical systems
 
 -Project-
 Intrusion Detection for Industrial Control Networks
 
 -Group 8-
 Hassan Ghalayini - hassang@student.chalmers.se
 Malama Kasanda - malama@student.chalmers.se
 Vaios Taxiarchis - vaios@student.chalmers.se

 Modified by Robin Krahl <guskraro@student.gu.se>, Group 3:
 - Write sensor readings and distance to text files
 - Take the arguments N, L, r from argc
 - Formatting
 
 */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "midbro.h"

int main(int argc, char **argv)
{
	clock_t begin;
	int l=0;
	double t=30;

	if (argc != 4) {
		fprintf(stderr, "Usage: %s N L r\n", argv[0]);
		fprintf(stderr, "    Example values: N = 1000, L = 500, r = 18\n");
		fprintf(stderr, "Wrong argument count. Aborting.\n");
		return 1;
	}

	int N = atoi(argv[1]);
	int L = atoi(argv[2]);
	int r = atoi(argv[3]);

	FILE *file_sensor = fopen("sensor.dat", "w");
	FILE *file_distance = fopen("distance.dat", "w");

	/* Arrays and variables */
	int sL=86336;
	double s[sL];
	double U[L][r];
	double X[L];
	double product_Xt_P_X;
	double product_Xt_X;
	int i=0,j=0,c=0,d=0,k=0;
	double sum=0.0,dist=0.0;

	start_data_capture();

	/* File Descriptor to read projection matrix from U.txt */
	FILE *file;
	char ch='a';
	int flag=0;
	file=fopen("U.txt", "r");
	if (!file) {
		fprintf(stderr, "Could not open U.txt. Aborting.\n");
		return 1;
	}
	printf("  >Reading U[%dx%d] matrix from .txt file...",L,r);
	/* Read all values to an array */
	for(i=0;i<L;i++)
	{
		if(flag==1){break;}
		for(j=0;j<r;j++)
		{
			/* Use %lf format specifier, to read doubles with scanf */
			if(!fscanf(file,"%lf",&U[i][j]))
				break;
			/* Break the inner loop and set flag=true */
			ch = getc(file);
			if(ch == EOF)
			{
				flag=1;
				break;
			}
			/* Break the inner loop when find \n */
			else if(ch - '0'== -38)
				break;
		}
	}
	/* Close File Descriptor */
	fclose(file);
	printf("Completed!\n");

	for(i=0;i<N;i++)
	{
		s[i] = (double)request_value();
	}

	int p=1;
	X[0]=0;

	for(i=N-L+1;i<N;i++)
	{
		X[p] = s[i];
		sum = sum + X[p]*X[p];
		p++;
	}
	product_Xt_X = sum;
	sum = 0;

	begin = clock();
	while(1)
	{
		int value = request_value();
		s[p] = (double) value;
		fprintf(file_sensor, "%d\n", value);

		/* Xt[1xL] * X[Lx1] */
		product_Xt_X = product_Xt_X - X[0]*X[0] + s[p]*s[p];

		/* Generate new test vector Xtest */
		for(j=0;j<L-1;j++)
		{
			X[j] = X[j+1];
		}
		X[L-1] = s[p];

		product_Xt_P_X = 0;
		/* P_1 = Xt[1xL] * U[Lxr] */
		for (d=0;d<r;d++)
		{
			for (k=0;k<L;k++)
			{
				sum = sum + X[k]*U[k][d];
			}
			product_Xt_P_X = product_Xt_P_X + sum*sum;
			sum = 0;
		}

		dist = (product_Xt_X - product_Xt_P_X)/L;
		p++;

		printf("%lf\n",dist);
		fprintf(file_distance, "%lf\n", dist);
	}

	fclose(file_sensor);
	fclose(file_distance);

	printf(" [Program exits]\n");
	/* Stop timer */
	clock_t end = clock();

	/* Print the time elapsed */
	printf("Time elapsed: %f milliseconds\n", 1000*((double)(end - begin) / CLOCKS_PER_SEC));

	return 0;
}
