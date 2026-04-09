"use client";

import { useState } from "react";
import Link from "next/link";
import { parent, school, messages, dailyReport } from "@/lib/mock-data";

type Tab = "feed" | "messages";

export default function ParentPortal() {
  const [tab, setTab] = useState<Tab>("feed");
  const [newMessage, setNewMessage] = useState("");
  const [chatMessages, setChatMessages] = useState(messages.filter(m => !m.broadcast));
  const [broadcast] = useState(messages.find(m => m.broadcast));
  const [absentSubmitted, setAbsentSubmitted] = useState(false);

  function sendMessage() {
    if (!newMessage.trim()) return;
    setChatMessages(prev => [...prev, {
      id: String(Date.now()),
      from: parent.name,
      fromRole: "parent",
      to: "Laura Martínez",
      toRole: "teacher",
      text: newMessage,
      time: new Date().toLocaleTimeString("es-ES", { hour: "2-digit", minute: "2-digit" }),
      read: true,
      avatar: "SR",
    }]);
    setNewMessage("");
  }

  const moodEmoji: Record<string, string> = { feliz: "😄", tranquilo: "😊", cansado: "😪", triste: "😢" };
  const mealLabel: Record<string, string> = { bien: "Comió bien", algo: "Comió algo", "no comió": "No comió" };
  const napLabel: Record<string, string> = { bien: "Durmió bien", inquieta: "Durmió inquieto", "no durmió": "No durmió" };

  const tabs: { id: Tab; label: string; icon: string }[] = [
    { id: "feed", label: "Hoy", icon: "🌟" },
    { id: "messages", label: "Mensajes", icon: "💬" },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Top nav */}
      <nav className="bg-white border-b border-gray-100 px-4 py-3 flex items-center justify-between sticky top-0 z-10 shadow-sm">
        <div className="flex items-center gap-3">
          <Link href="/" className="text-gray-400 hover:text-gray-600 text-xl">←</Link>
          <div>
            <div className="text-sm font-semibold text-gray-900">{school.name}</div>
            <div className="text-xs text-gray-400">Aula Girasoles · {parent.child}</div>
          </div>
        </div>
        <div className="w-8 h-8 rounded-full bg-purple-100 text-purple-700 text-xs font-bold flex items-center justify-center">SR</div>
      </nav>

      {/* Tab bar */}
      <div className="bg-white border-b border-gray-100 flex">
        {tabs.map(t => (
          <button
            key={t.id}
            onClick={() => setTab(t.id)}
            className={`flex-1 py-3 text-xs font-medium flex flex-col items-center gap-1 transition-colors ${
              tab === t.id ? "text-purple-600 border-b-2 border-purple-600" : "text-gray-400 hover:text-gray-600"
            }`}
          >
            <span className="text-lg">{t.icon}</span>
            {t.label}
          </button>
        ))}
      </div>

      <div className="max-w-2xl mx-auto p-4">

        {/* FEED */}
        {tab === "feed" && (
          <div className="space-y-4">
            {/* Greeting */}
            <div className="mt-2">
              <h2 className="text-lg font-semibold text-gray-900">Hola, Sofía 👋</h2>
              <p className="text-sm text-gray-500">El día de Pablo · {dailyReport.date}</p>
            </div>

            {/* Broadcast announcement */}
            {broadcast && (
              <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4">
                <div className="text-xs font-medium text-amber-700 mb-1">📢 Aviso del colegio</div>
                <p className="text-sm text-amber-900">{broadcast.text}</p>
                <div className="text-xs text-amber-500 mt-2">{broadcast.time} · Carmen García, Directora</div>
              </div>
            )}

            {/* Pablo's daily card */}
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
              <div className="bg-gradient-to-r from-purple-500 to-indigo-500 px-5 py-4">
                <div className="text-white text-sm font-medium opacity-80">Diario de hoy</div>
                <div className="text-white text-xl font-bold mt-1">{parent.child}</div>
                <div className="flex items-center gap-2 mt-2">
                  <span className="text-2xl">{moodEmoji[dailyReport.childReport.mood] ?? "😊"}</span>
                  <span className="text-white text-sm capitalize">{dailyReport.childReport.mood}</span>
                </div>
              </div>

              <div className="p-5 space-y-4">
                {/* Meal & nap row */}
                <div className="grid grid-cols-2 gap-3">
                  <div className="bg-gray-50 rounded-xl p-3 text-center">
                    <div className="text-xl mb-1">🍽️</div>
                    <div className="text-xs font-medium text-gray-700">{mealLabel[dailyReport.childReport.meal] ?? "—"}</div>
                  </div>
                  <div className="bg-gray-50 rounded-xl p-3 text-center">
                    <div className="text-xl mb-1">😴</div>
                    <div className="text-xs font-medium text-gray-700">{napLabel[dailyReport.childReport.nap] ?? "—"}</div>
                  </div>
                </div>

                {/* Teacher note */}
                <div>
                  <div className="text-xs font-medium text-gray-400 uppercase tracking-wide mb-2">Nota de su profesora</div>
                  <p className="text-sm text-gray-700 leading-relaxed">{dailyReport.childReport.note}</p>
                </div>

                {/* Activities */}
                <div>
                  <div className="text-xs font-medium text-gray-400 uppercase tracking-wide mb-2">Actividades del grupo</div>
                  <div className="flex flex-wrap gap-2">
                    {dailyReport.activities.map(a => (
                      <span key={a} className="text-xs bg-indigo-50 text-indigo-700 rounded-full px-3 py-1">{a}</span>
                    ))}
                  </div>
                </div>

                {/* Group note */}
                <div>
                  <div className="text-xs font-medium text-gray-400 uppercase tracking-wide mb-2">Nota del aula</div>
                  <p className="text-sm text-gray-600 italic">"{dailyReport.groupNote}"</p>
                </div>
              </div>
            </div>

            {/* Photos */}
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <div className="text-sm font-semibold text-gray-700 mb-3">Fotos de hoy</div>
              <div className="grid grid-cols-2 gap-3">
                {dailyReport.photos.map(photo => (
                  <div key={photo.id} className="bg-gradient-to-br from-purple-50 to-indigo-50 rounded-xl p-6 text-center border border-purple-100">
                    <div className="text-5xl mb-2">{photo.emoji}</div>
                    <div className="text-xs font-medium text-gray-700">{photo.caption}</div>
                    {photo.children.includes(parent.child) && (
                      <div className="mt-2 text-xs bg-purple-100 text-purple-700 rounded-full px-2 py-0.5 inline-block">Pablo aparece</div>
                    )}
                  </div>
                ))}
              </div>
              <div className="mt-3 text-center">
                <button className="text-xs text-purple-600 hover:text-purple-800 font-medium">Ver todas las fotos →</button>
              </div>
            </div>

            {/* Absent notification */}
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
              <div className="text-sm font-semibold text-gray-700 mb-1">¿Pablo faltará mañana?</div>
              <p className="text-xs text-gray-400 mb-3">Avisa en un toque. Sin llamadas, sin WhatsApp.</p>
              {absentSubmitted ? (
                <div className="text-sm text-emerald-700 bg-emerald-50 rounded-xl p-3 text-center">✓ Notificación enviada a Laura</div>
              ) : (
                <button onClick={() => setAbsentSubmitted(true)} className="w-full text-sm border border-gray-200 rounded-xl py-2.5 text-gray-600 hover:bg-gray-50 transition-colors font-medium">
                  Notificar ausencia mañana
                </button>
              )}
            </div>
          </div>
        )}

        {/* MESSAGES */}
        {tab === "messages" && (
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-900 mt-2">Mensajes</h2>

            {/* Thread with teacher */}
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
              <div className="px-4 py-3 border-b border-gray-50 flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-indigo-100 text-indigo-700 text-xs font-bold flex items-center justify-center">LM</div>
                <div>
                  <div className="text-sm font-medium text-gray-900">Laura Martínez</div>
                  <div className="text-xs text-gray-400">Profesora · Aula Girasoles</div>
                </div>
              </div>

              <div className="p-4 space-y-3 max-h-72 overflow-y-auto">
                {chatMessages.map(msg => (
                  <div key={msg.id} className={`flex ${msg.fromRole === "parent" ? "justify-end" : "justify-start"}`}>
                    <div className={`max-w-xs rounded-2xl px-4 py-2.5 text-sm ${
                      msg.fromRole === "parent"
                        ? "bg-purple-600 text-white rounded-br-sm"
                        : "bg-gray-100 text-gray-800 rounded-bl-sm"
                    }`}>
                      <p>{msg.text}</p>
                      <p className={`text-xs mt-1 ${msg.fromRole === "parent" ? "text-purple-200" : "text-gray-400"}`}>{msg.time}</p>
                    </div>
                  </div>
                ))}
              </div>

              <div className="p-3 border-t border-gray-100 flex gap-2">
                <input
                  type="text"
                  value={newMessage}
                  onChange={e => setNewMessage(e.target.value)}
                  onKeyDown={e => e.key === "Enter" && sendMessage()}
                  placeholder="Escribe a Laura..."
                  className="flex-1 text-sm bg-gray-50 rounded-full px-4 py-2 outline-none border border-gray-200 focus:border-purple-300"
                />
                <button
                  onClick={sendMessage}
                  className="w-10 h-10 bg-purple-600 hover:bg-purple-700 text-white rounded-full flex items-center justify-center text-lg transition-colors"
                >
                  ↑
                </button>
              </div>
            </div>

            {/* Broadcast announcement */}
            {broadcast && (
              <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4">
                <div className="flex items-center gap-2 mb-2">
                  <div className="w-7 h-7 rounded-full bg-amber-200 text-amber-800 text-xs font-bold flex items-center justify-center">CG</div>
                  <span className="text-xs font-medium text-amber-700">Aviso del colegio</span>
                  <span className="text-xs text-amber-400 ml-auto">{broadcast.time}</span>
                </div>
                <p className="text-sm text-amber-900">{broadcast.text}</p>
                <div className="text-xs text-amber-500 mt-2">Carmen García, Directora</div>
              </div>
            )}

            <div className="bg-gray-50 border border-gray-100 rounded-2xl p-4 text-center text-xs text-gray-400">
              🔒 Tus mensajes son privados. Nunca se comparten con otros padres.
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
