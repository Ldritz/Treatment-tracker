import type { Metadata, Viewport } from "next";
import { Nunito, Roboto_Mono } from "next/font/google";
import "./globals.css";

const nunito = Nunito({
  variable: "--font-nunito",
  subsets: ["latin"],
  weight: ["400", "700", "900"],
});

const robotoMono = Roboto_Mono({
  variable: "--font-roboto-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Experiment 626: Quail Tracker",
  description: "Daily data collection for Japanese Quail laying performance",
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "Quail Tracker",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  themeColor: "#E3F2FD",
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${nunito.variable} ${robotoMono.variable} antialiased`}
      >
        <div className="max-w-4xl mx-auto p-4 sm:p-6 lg:p-8 min-h-screen">
          {children}
        </div>
      </body>
    </html>
  );
}
