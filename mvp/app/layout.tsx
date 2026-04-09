import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Kindi — Comunicación para escuelas infantiles",
  description: "La plataforma de comunicación para escuelas infantiles en España",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="es" className="h-full">
      <body className="min-h-full bg-gray-50 font-sans">{children}</body>
    </html>
  );
}
