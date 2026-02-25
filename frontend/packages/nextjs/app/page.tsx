"use client";

import Image from "next/image";
import { StealthAuctionComponent } from "./StealthAuctionComponent";
import type { NextPage } from "next";
import { useAccount } from "wagmi";

const Home: NextPage = () => {
  const { address: connectedAddress } = useAccount();

  return (
    <div className="stealth-page">
      <section className="stealth-hero px-6 py-14 md:py-20">
        <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
          <div className="space-y-6 lg:col-span-6">
            <div className="stealth-pill">v4-powered confidential execution layer</div>
            <h1 className="text-4xl md:text-6xl font-semibold leading-tight tracking-tight">
              Confidential auctions,
              <span className="stealth-highlight"> refined for execution.</span>
            </h1>
            <p className="text-base md:text-xl text-base-content/75 max-w-xl leading-relaxed">
              StealthAuction combines Uniswap v4 hooks and CoFHE to enable confidential price discovery with public,
              verifiable settlement.
            </p>
            <div className="flex flex-wrap gap-3">
              <a href="#interactive" className="btn btn-neutral btn-lg">
                Launch Auction Workspace
              </a>
              <a
                href="https://github.com/Najnomics/StealthAuction/tree/v2/docs"
                target="_blank"
                rel="noreferrer"
                className="btn btn-ghost btn-lg"
              >
                Read Protocol Docs
              </a>
            </div>
            <p className="text-xs text-base-content/60">
              Wallet status: {connectedAddress ? connectedAddress : "Connect wallet to start encrypted operations"}
            </p>
          </div>

          <div className="lg:col-span-6">
            <div className="stealth-banner-frame">
              <Image
                src="/brand/prudlabs-banner.png"
                alt="prud_Labs banner"
                width={1200}
                height={675}
                className="w-full h-auto rounded-2xl border border-white/15"
                priority
              />
            </div>
          </div>
        </div>
      </section>

      <section className="px-6 py-8 md:py-12">
        <div className="max-w-7xl mx-auto grid grid-cols-1 md:grid-cols-3 gap-5">
          <div className="stealth-card">
            <h3 className="font-semibold text-lg">Encrypted Price Curve</h3>
            <p className="text-sm text-base-content/75">
              Start price, end price, and duration are handled with CoFHE encrypted input payloads.
            </p>
          </div>
          <div className="stealth-card">
            <h3 className="font-semibold text-lg">Signer-Aware Bid Payloads</h3>
            <p className="text-sm text-base-content/75">
              Generate `ENC_BID1` and `ENC_BID2` under the exact wallet that will broadcast each bid.
            </p>
          </div>
          <div className="stealth-card">
            <h3 className="font-semibold text-lg">Sepolia-Tested E2E Flow</h3>
            <p className="text-sm text-base-content/75">
              Proven workflow from encrypted auction creation to bid submission, settlement, and reveal.
            </p>
          </div>
        </div>
      </section>

      <section className="px-6 py-4">
        <div className="max-w-7xl mx-auto grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="stealth-mini-card">
            <p className="m-0 text-xs uppercase tracking-[0.16em] text-base-content/60">Create</p>
            <p className="m-0 text-sm mt-1">Launch auctions with encrypted supply and pricing parameters.</p>
          </div>
          <div className="stealth-mini-card">
            <p className="m-0 text-xs uppercase tracking-[0.16em] text-base-content/60">Bid</p>
            <p className="m-0 text-sm mt-1">Collect signer-bound encrypted bids from participant wallets.</p>
          </div>
          <div className="stealth-mini-card">
            <p className="m-0 text-xs uppercase tracking-[0.16em] text-base-content/60">Settle</p>
            <p className="m-0 text-sm mt-1">Finalize transparently on-chain with verifiable output.</p>
          </div>
        </div>
      </section>

      <section id="interactive" className="px-6 pb-16 pt-4">
        <div className="max-w-7xl mx-auto">
          <div className="mb-6 md:mb-8">
            <h2 className="text-3xl md:text-4xl font-bold">Interactive Auction Workspace</h2>
            <p className="text-base-content/75 text-base md:text-lg">
              Create auctions, submit encrypted bids, inspect state, and export Sepolia-ready payloads from one
              interface.
            </p>
          </div>
          <div className="stealth-workspace-shell">
            <StealthAuctionComponent />
          </div>
        </div>
      </section>
    </div>
  );
};

export default Home;
