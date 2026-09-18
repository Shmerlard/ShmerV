static int initial_value;

int main(void)
{
    if (initial_value != 0) {
        return 1;
    }

    return 42;
}
