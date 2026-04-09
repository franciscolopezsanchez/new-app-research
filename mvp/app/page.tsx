import Link from "next/link";

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-50 via-white to-purple-50 flex flex-col items-center justify-center p-6">
      {/* Logo */}
      <div className="mb-12 text-center">
        <div className="text-5xl mb-3">🌙</div>
        <h1 className="text-4xl font-bold text-gray-900 tracking-tight">Kindi</h1>
        <p className="mt-2 text-gray-500 text-lg">Comunicación segura para tu escuela infantil</p>
      </div>

      {/* School badge */}
      <div className="mb-10 bg-white rounded-2xl px-6 py-3 shadow-sm border border-gray-100 text-sm text-gray-600 font-medium">
        📍 Escuela Infantil Sol y Luna — Demo
      </div>

      {/* Role selector */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-5 w-full max-w-lg">
        <Link href="/teacher" className="group bg-white rounded-2xl p-8 shadow-sm border border-gray-100 hover:border-indigo-300 hover:shadow-md transition-all text-center">
          <div className="text-4xl mb-4">👩‍🏫</div>
          <div className="text-lg font-semibold text-gray-900 group-hover:text-indigo-700">Soy profesora</div>
          <div className="mt-1 text-sm text-gray-400">Laura Martínez</div>
          <div className="mt-4 text-xs bg-indigo-50 text-indigo-600 rounded-full py-1 px-3 inline-block">Aula Girasoles</div>
        </Link>

        <Link href="/parent" className="group bg-white rounded-2xl p-8 shadow-sm border border-gray-100 hover:border-purple-300 hover:shadow-md transition-all text-center">
          <div className="text-4xl mb-4">👨‍👩‍👦</div>
          <div className="text-lg font-semibold text-gray-900 group-hover:text-purple-700">Soy madre/padre</div>
          <div className="mt-1 text-sm text-gray-400">Sofía Rodríguez</div>
          <div className="mt-4 text-xs bg-purple-50 text-purple-600 rounded-full py-1 px-3 inline-block">Pablo, 2 años</div>
        </Link>
      </div>

      {/* Tagline */}
      <div className="mt-14 flex flex-col items-center gap-2">
        <div className="flex gap-4 text-xs text-gray-400">
          <span>🔒 RGPD</span>
          <span>📱 iOS & Android</span>
          <span>🇪🇸 Hecho para España</span>
        </div>
        <p className="text-xs text-gray-400 text-center max-w-sm">
          Reemplaza los grupos de WhatsApp con una plataforma privada y segura.
        </p>
      </div>
    </div>
  );
}
