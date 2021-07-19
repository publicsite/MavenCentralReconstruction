#include <stdio.h>
#include <stdlib.h>

int main (int argc, char *argv[])
{
	if ( argc != 2)
	{
		perror("Argv1: File path");
		exit(1);
	}

	FILE * pFile;
	int *theLine = NULL;
	int theLineSize = 0;
	int c;
	int n = 0;
	int lineNumber = 1;
	short printLine = 0;
	short printLineNumber = 0;
	pFile=fopen (argv[1],"r");
	if (pFile==NULL)
	{
		perror ("Error opening file");
		exit(1);
	}
	else
	{
		do {
			c = fgetc (pFile);

			if (c != '\n' && c != '\r')
			{
				theLine = realloc(theLine, (theLineSize + 1) * sizeof(int));

     				if (theLine==NULL)
				{
					perror("Realloc failed");
					exit(1);
				}

				theLine[theLineSize] = c;

				++theLineSize;
			}

			if (c == '\n' )
			{
				if (printLine == 1){
					int printIndex;
					for (printIndex=0; printIndex < theLineSize; ++printIndex) 
					{
							printf("%c", theLine[printIndex]);
							fflush(stdout);
					}

							printf("\t%d", lineNumber);
							fflush(stdout);

					printLine = 0;
				}

				if (printLineNumber == 1)
				{
					printf(",%d\n",lineNumber);
					fflush(stdout);
					printLineNumber = 0;
				}

				free(theLine);
				theLine = malloc(sizeof(char));
				theLineSize=0;

				++lineNumber;
			}
			else if (c == '{')
			{
				n++;
				if (n == 2) printLine = 1;
			}
			else if (c == '}')
			{
				if (n == 2)
				{
					printLineNumber=1;
				}
				n--;
			}
		} while (c != EOF);
		fclose (pFile);
	}
	return 0;
}