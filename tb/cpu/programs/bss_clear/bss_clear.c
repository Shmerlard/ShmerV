static unsigned int zero_initialized_value;

int main(void)
{
    if (zero_initialized_value != 0) {
        return 1;
    }

    return 42;
}
