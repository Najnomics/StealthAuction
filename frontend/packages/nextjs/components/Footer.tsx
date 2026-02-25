import React from "react";
import Link from "next/link";
import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";
import { SwitchTheme } from "~~/components/SwitchTheme";

/**
 * Site footer
 */
export const Footer = () => {
  return (
    <footer className="border-t border-base-300/70 px-6 py-8 bg-base-100/75 backdrop-blur-lg">
      <div className="max-w-7xl mx-auto flex flex-col md:flex-row gap-4 md:gap-2 items-start md:items-center justify-between">
        <div>
          <p className="m-0 font-semibold text-lg">StealthAuction</p>
          <p className="m-0 text-sm text-base-content/70">
            Confidential Dutch auctions powered by Uniswap v4 hooks and CoFHE.
          </p>
        </div>
        <div className="flex items-center gap-5">
          <Link href="/" className="link text-sm">
            Home
          </Link>
          <a
            href="https://github.com/Najnomics/StealthAuction"
            target="_blank"
            rel="noreferrer"
            className="link text-sm inline-flex items-center gap-1"
          >
            GitHub <ArrowTopRightOnSquareIcon className="h-3.5 w-3.5" />
          </a>
          <SwitchTheme />
        </div>
      </div>
    </footer>
  );
};
