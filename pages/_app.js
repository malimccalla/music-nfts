import "../styles/globals.css";

import Link from "next/link";

function MyApp({ Component, pageProps }) {
  return (
    <div>
      <nav className="border-b p-6">
        <p className="text-4xl font-bold">NFT Marketplace</p>
        <div className="mt-4">
          <Link href="/">
            <a className="mr-4">Home</a>
          </Link>
          <Link href="/create-item">
            <a className="mr-4">Create Item</a>
          </Link>
          <Link href="/my-assets">
            <a className="mr-4">My Assets</a>
          </Link>
          <Link href="/creator-dashboard">
            <a className="mr-4">Dashboard</a>
          </Link>
        </div>
      </nav>
      <Component {...pageProps} />
    </div>
  );
}

export default MyApp;
