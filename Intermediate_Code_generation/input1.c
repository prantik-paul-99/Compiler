int fact(int n)
{
	if(n>1) return n*fact(n-1);
	else return 1;
}

int main()
{
	int n;
	n = fact(3);
	printf(n);
}
