export async function sleep(second: number): Promise<void> {
    return await new Promise(resolve => setTimeout(resolve, second * 1000));
}