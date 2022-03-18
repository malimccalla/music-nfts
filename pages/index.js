import axios from "axios";
import { ethers } from "ethers";
import Image from "next/image";
import { useEffect, useState } from "react";
import Web3Modal from "web3modal";

import NFT from "../artifacts/contracts/NFT.sol/NFT.json";
import NFTMarket from "../artifacts/contracts/NFTMarket.sol/NFTMarket.json";
import { nftAddress, nftMarketAddress } from "../config";

export default function Home() {
  const [nfts, setNfts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadNFTs();
  }, []);

  async function loadNFTs() {
    const provider = new ethers.providers.JsonRpcProvider();
    const tokenContract = new ethers.Contract(nftAddress, NFT.abi, provider);
    const marketContract = new ethers.Contract(
      nftMarketAddress,
      NFTMarket.abi,
      provider
    );

    const data = await marketContract.getMarketItems();

    const items = await Promise.all(
      data.map(async (i) => {
        const tokenUri = await tokenContract.tokenURI(i.tokenId);
        const meta = await axios.get(tokenUri);

        let price = ethers.utils.formatUnits(i.price.toString(), "ether");

        const item = {
          price,
          tokenId: i.tokenId.toNumber(),
          seller: i.seller,
          owner: i.owner,
        };

        return item;
      })
    );

    setNfts(items);
    setLoading(false);

    // console.log(data);
  }

  async function buyNft(nft) {
    const web3Modal = new Web3Modal();
    const connection = await web3Modal.connect();
    const provider = new ethers.providers.Web3Provider(connection);

    const signer = provider.getSigner();

    const marketContract = new ethers.Contract(
      nftMarketAddress,
      NFTMarket.abi,
      signer
    );

    const price = ethers.utils.parseUnits(nft.price.toString(), "ether");

    const transaction = marketContract.createMarketSale(
      nftAddress,
      nft.tokenId,
      { value: price }
    );

    await transaction.wait();
    loadNFTs();
  }

  if (!loading && nfts.length < 1)
    return <h1 className="px-20 py-10 text-3xl">No items exist</h1>;

  return (
    <div className="flex justify-center">
      <div className="px-4" style={{ maxWidth: "1600px" }}>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 pt-4">
          {nfts.map((nft, i) => {
            return (
              <div key={i} className="border shadow rounded-xl overflow-hidden">
                <Image src={nft.image} alt={nft.name} />
                <div className="p-4">
                  <p
                    style={{ height: "64px" }}
                    className="text-2xl font-semibold"
                  >
                    {nft.name}
                  </p>
                  <div style={{ height: "70px", overflow: "hidden" }}>
                    <p className="text-gray-400">{nft.description}</p>
                  </div>
                </div>

                <div className="p-4 bg-black">
                  <p className="text-2xl font-bold text-white">
                    {nft.price} ETH
                  </p>
                  <button
                    className="mt-4 w-full bg-pink-500 text-white font-bold py-2 px-12 rounded"
                    onClick={() => buyNft(nft)}
                  >
                    Buy
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
