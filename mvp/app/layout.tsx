import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Kindi — El diario digital de tu escuela infantil",
  description: "Reemplaza los grupos de WhatsApp con una plataforma privada, segura y compatible con el RGPD para escuelas infantiles en España.",
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
