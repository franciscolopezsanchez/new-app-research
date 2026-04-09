"use client";

import { useState } from "react";
import Link from "next/link";
import { children as classChildren, teacher, school, messages, dailyReport, activities } from "@/lib/mock-data";

type Tab = "dashboard" | "attendance" | "report" | "messages";

const mealEmoji: Record<string, string> = { bien: "😊", algo: "😐", "no comió": "😟" };
const napEmoji: Record<string, string> = { bien: "😴", inquieta: "😕", "no durmió": "😣" };

export default function TeacherPortal() {
  const [tab, setTab] = useState<Tab>("dashboard");
  const [attendance, setAttendance] = useState(classChildren);
  const [selectedActivities, setSelectedActivities] = useState<string[]>(dailyReport.activities);
  const [reportNote, setReportNote] = useState(dailyReport.groupNote);
  const [reportPublished, setReportPublished] = useState(false);
  const [newMessage, setNewMessage] = useState("");
  const [chatMessages, setChatMessages] = useState(messages.filter(m => !m.broadcast));
  const [broadcast] = useState(messages.find(m => m.broadcast));

  const presentCount = attendance.filter(c => c.present).length;
  const absentCount = attendance.filter(c => !c.present).length;
  const reportDone = attendance.filter(c => c.present && c.meal).length;

  function togglePresent(id: string) {
    setAttendance(prev => prev.map(c => c.id === id ? { ...c, present: !c.present } : c));
  }

  function markAllPresent() {
    setAttendance(prev => prev.map(c => ({ ...c, present: true })));
  }

  function toggleActivity(a: string) {
    setSelectedActivities(prev =>
      prev.includes(a) ? prev.filter(x => x !== a) : [...prev, a]
    );
  }

  function sendMessage() {
    if (!newMessage.trim()) return;
    setChatMessages(prev => [...prev, {
      id: String(Date.now()),
      from: teacher.name,
      fromRole: "teacher",
      to: "Sofía Rodríguez",
      toRole: "parent",
      text: newMessage,
      time: new Date().toLocaleTimeString("es-ES", { hour: "2-digit", minute: "2-digit" }),
      read: true,
      avatar: "LM",
    }]);
    setNewMessage("");
  }

  const tabs: { id: Tab; label: string; icon: string }[] = [
    { id: "dashboard", label: "Inicio", icon: "🏠" },
    { id: "attendance", label: "Asistencia", icon: "✅" },
    { id: "report", label: "Diario", icon: "📝" },
    { id: "messages", label: "Mensajes", icon: "💬" },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Top nav */}
      <nav className="bg-white border-b border-gray-100 px-4 py-3 flex items-center justify-between sticky top-0 z-10 shadow-sm">
        <div className="flex items-center gap-3">
          <Link href="/" className="text-gray-400 hover:text-gray-600 text-xl">←</Link>
          <div>
            <div className="text-sm font-semibold text-gray-900">{teacher.name}</div>
            <div className="text-xs text-gray-400">{teacher.classroom}</div>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-indigo-100 text-indigo-700 text-xs font-bold flex items-center justify-center">{teacher.avatar}</div>
        </div>
      </nav>

      {/* Tab bar */}
      <div className="bg-white border-b border-gray-100 flex">
        {tabs.map(t => (
          <button
            key={t.id}
            onClick={() => setTab(t.id)}
            className={`flex-1 py-3 text-xs font-medium flex flex-col items-center gap-1 transition-colors ${
              tab === t.id ? "text-indigo-600 border-b-2 border-indigo-600" : "text-gray-400 hover:text-gray-600"
            }`}
          >
            <span className="text-lg">{t.icon}</span>
            {t.label}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="max-w-2xl mx-auto p-4">

        {/* DASHBOARD */}
        {tab === "dashboard" && (
          <div className="space-y-4">
            <div className="mt-2">
              <h2 className="text-lg font-semibold text-gray-900">Buenos días, Laura 👋</h2>
              <p className="text-sm text-gray-500">{dailyReport.date}</p>
            </div>

            {/* Stats row */}
            <div className="grid grid-cols-3 gap-3">
              <div className="bg-white rounded-2xl p-4 text-center shadow-sm border border-gray-100">
                <div className="text-3xl font-bold text-indigo-600">{presentCount}</div>
                <div className="text-xs text-gray-400 mt-1">Presentes</div>
              </div>
              <div className="bg-white rounded-2xl p-4 text-center shadow-sm border border-gray-100">
                <div className="text-3xl font-bold text-amber-500">{absentCount}</div>
                <div className="text-xs text-gray-400 mt-1">Ausentes</div>
              </div>
              <div className="bg-white rounded-2xl p-4 text-center shadow-sm border border-gray-100">
                <div className="text-3xl font-bold text-emerald-500">{reportPublished ? "✓" : `${reportDone}/${presentCount}`}</div>
                <div className="text-xs text-gray-400 mt-1">Diario</div>
              </div>
            </div>

            {/* Quick actions */}
            <div className="grid grid-cols-2 gap-3">
              <button onClick={() => setTab("attendance")} className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100 hover:border-indigo-200 text-left transition-all">
                <div className="text-2xl mb-2">✅</div>
                <div className="font-semibold text-gray-800 text-sm">Pasar lista</div>
                <div className="text-xs text-gray-400 mt-1">{presentCount}/{attendance.length} marcados</div>
              </button>
              <button onClick={() => setTab("report")} className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100 hover:border-indigo-200 text-left transition-all">
                <div className="text-2xl mb-2">📝</div>
                <div className="font-semibold text-gray-800 text-sm">Diario del día</div>
                <div className="text-xs text-gray-400 mt-1">{reportPublished ? "Publicado ✓" : "Pendiente"}</div>
              </button>
              <button onClick={() => setTab("messages")} className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100 hover:border-indigo-200 text-left transition-all">
                <div className="text-2xl mb-2">💬</div>
                <div className="font-semibold text-gray-800 text-sm">Mensajes</div>
                <div className="text-xs text-gray-400 mt-1">1 sin leer</div>
              </button>
              <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100 text-left opacity-60">
                <div className="text-2xl mb-2">📸</div>
                <div className="font-semibold text-gray-800 text-sm">Fotos</div>
                <div className="text-xs text-gray-400 mt-1">2 subidas hoy</div>
              </div>
            </div>

            {/* Announcement banner */}
            {broadcast && (
              <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4">
                <div className="text-xs font-medium text-amber-700 mb-1">Aviso de Dirección</div>
                <div className="text-sm text-amber-900">{broadcast.text}</div>
                <div className="text-xs text-amber-500 mt-2">{broadcast.time}</div>
              </div>
            )}
          </div>
        )}

        {/* ATTENDANCE */}
        {tab === "attendance" && (
          <div className="space-y-4">
            <div className="flex items-center justify-between mt-2">
              <h2 className="text-lg font-semibold text-gray-900">Asistencia</h2>
              <button onClick={markAllPresent} className="text-xs bg-indigo-600 text-white rounded-full px-4 py-2 hover:bg-indigo-700 transition-colors">
                Todos presentes
              </button>
            </div>
            <p className="text-sm text-gray-400">{dailyReport.date}</p>

            <div className="space-y-2">
              {attendance.map(child => (
                <div key={child.id} className={`bg-white rounded-2xl p-4 shadow-sm border flex items-center justify-between transition-all ${child.present ? "border-gray-100" : "border-amber-200 bg-amber-50"}`}>
                  <div className="flex items-center gap-3">
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center text-sm font-bold ${child.present ? "bg-indigo-100 text-indigo-700" : "bg-amber-100 text-amber-700"}`}>
                      {child.name.split(" ").map(n => n[0]).join("").slice(0, 2)}
                    </div>
                    <div>
                      <div className="font-medium text-gray-900 text-sm">{child.name}</div>
                      {!child.present && child.parentNotified && (
                        <div className="text-xs text-amber-600">Familia notificó ausencia</div>
                      )}
                      {!child.present && !child.parentNotified && (
                        <div className="text-xs text-red-500">⚠️ Sin notificación</div>
                      )}
                      {child.late && <div className="text-xs text-blue-500">Llegó tarde</div>}
                    </div>
                  </div>
                  <button
                    onClick={() => togglePresent(child.id)}
                    className={`w-10 h-10 rounded-full flex items-center justify-center text-lg transition-all ${
                      child.present ? "bg-emerald-100 text-emerald-600 hover:bg-red-100 hover:text-red-500" : "bg-gray-100 text-gray-400 hover:bg-emerald-100 hover:text-emerald-600"
                    }`}
                  >
                    {child.present ? "✓" : "○"}
                  </button>
                </div>
              ))}
            </div>

            <div className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 text-center">
              <div className="text-sm text-gray-500">
                <span className="text-emerald-600 font-semibold">{presentCount} presentes</span> · <span className="text-amber-600 font-semibold">{absentCount} ausentes</span> · {attendance.length} total
              </div>
            </div>
          </div>
        )}

        {/* DAILY REPORT */}
        {tab === "report" && (
          <div className="space-y-4">
            <div className="flex items-center justify-between mt-2">
              <h2 className="text-lg font-semibold text-gray-900">Diario del día</h2>
              {!reportPublished ? (
                <button
                  onClick={() => setReportPublished(true)}
                  className="text-xs bg-indigo-600 text-white rounded-full px-4 py-2 hover:bg-indigo-700 transition-colors"
                >
                  Publicar
                </button>
              ) : (
                <span className="text-xs bg-emerald-100 text-emerald-700 rounded-full px-4 py-2 font-medium">Publicado ✓</span>
              )}
            </div>
            <p className="text-sm text-gray-400">{dailyReport.date}</p>

            {reportPublished && (
              <div className="bg-emerald-50 border border-emerald-200 rounded-2xl p-4 text-sm text-emerald-800">
                ✓ Las familias han recibido una notificación con el diario de hoy.
              </div>
            )}

            {/* Activities */}
            <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
              <div className="text-sm font-semibold text-gray-700 mb-3">Actividades del día</div>
              <div className="flex flex-wrap gap-2">
                {activities.map(a => (
                  <button
                    key={a}
                    onClick={() => !reportPublished && toggleActivity(a)}
                    className={`text-xs rounded-full px-3 py-1.5 transition-all ${
                      selectedActivities.includes(a)
                        ? "bg-indigo-600 text-white"
                        : "bg-gray-100 text-gray-500 hover:bg-indigo-50"
                    } ${reportPublished ? "cursor-default" : ""}`}
                  >
                    {a}
                  </button>
                ))}
              </div>
            </div>

            {/* Group note */}
            <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
              <div className="text-sm font-semibold text-gray-700 mb-3">Nota del grupo</div>
              <textarea
                value={reportNote}
                onChange={e => !reportPublished && setReportNote(e.target.value)}
                readOnly={reportPublished}
                rows={3}
                className="w-full text-sm text-gray-700 resize-none outline-none bg-transparent placeholder-gray-300"
                placeholder="¿Cómo ha ido el día? Escribe una nota para todas las familias..."
              />
            </div>

            {/* Per-child summary */}
            <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
              <div className="text-sm font-semibold text-gray-700 mb-3">Resumen por niño</div>
              <div className="space-y-3">
                {attendance.filter(c => c.present).map(child => (
                  <div key={child.id} className="flex items-center justify-between text-sm border-b border-gray-50 pb-3 last:border-0 last:pb-0">
                    <span className="text-gray-700 font-medium">{child.name.split(" ")[0]}</span>
                    <div className="flex gap-3 text-base">
                      <span title="Comida">{mealEmoji[child.meal ?? ""] ?? "—"}</span>
                      <span title="Siesta">{napEmoji[child.nap ?? ""] ?? "—"}</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Photos */}
            <div className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
              <div className="text-sm font-semibold text-gray-700 mb-3">Fotos del día</div>
              <div className="grid grid-cols-2 gap-3">
                {dailyReport.photos.map(photo => (
                  <div key={photo.id} className="bg-gray-50 rounded-xl p-4 text-center border border-gray-100">
                    <div className="text-4xl mb-2">{photo.emoji}</div>
                    <div className="text-xs font-medium text-gray-700">{photo.caption}</div>
                    <div className="text-xs text-gray-400 mt-1">{photo.children.length} niños</div>
                  </div>
                ))}
                <button className="bg-gray-50 rounded-xl p-4 text-center border border-dashed border-gray-200 text-gray-400 hover:border-indigo-300 hover:text-indigo-400 transition-all">
                  <div className="text-3xl mb-1">+</div>
                  <div className="text-xs">Añadir foto</div>
                </button>
              </div>
            </div>
          </div>
        )}

        {/* MESSAGES */}
        {tab === "messages" && (
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-900 mt-2">Mensajes</h2>

            {/* Broadcast */}
            {broadcast && (
              <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4">
                <div className="flex items-center gap-2 mb-2">
                  <div className="w-7 h-7 rounded-full bg-amber-200 text-amber-800 text-xs font-bold flex items-center justify-center">{broadcast.avatar}</div>
                  <span className="text-xs font-medium text-amber-700">Aviso de Dirección</span>
                  <span className="text-xs text-amber-400 ml-auto">{broadcast.time}</span>
                </div>
                <p className="text-sm text-amber-900">{broadcast.text}</p>
              </div>
            )}

            {/* Thread */}
            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
              <div className="px-4 py-3 border-b border-gray-50 flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-purple-100 text-purple-700 text-xs font-bold flex items-center justify-center">SR</div>
                <div>
                  <div className="text-sm font-medium text-gray-900">Sofía Rodríguez</div>
                  <div className="text-xs text-gray-400">Familia de Pablo</div>
                </div>
              </div>

              <div className="p-4 space-y-3 max-h-64 overflow-y-auto">
                {chatMessages.map(msg => (
                  <div key={msg.id} className={`flex ${msg.fromRole === "teacher" ? "justify-end" : "justify-start"}`}>
                    <div className={`max-w-xs rounded-2xl px-4 py-2.5 text-sm ${
                      msg.fromRole === "teacher"
                        ? "bg-indigo-600 text-white rounded-br-sm"
                        : "bg-gray-100 text-gray-800 rounded-bl-sm"
                    }`}>
                      <p>{msg.text}</p>
                      <p className={`text-xs mt-1 ${msg.fromRole === "teacher" ? "text-indigo-200" : "text-gray-400"}`}>{msg.time}</p>
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
                  placeholder="Escribe un mensaje..."
                  className="flex-1 text-sm bg-gray-50 rounded-full px-4 py-2 outline-none border border-gray-200 focus:border-indigo-300"
                />
                <button
                  onClick={sendMessage}
                  className="w-10 h-10 bg-indigo-600 hover:bg-indigo-700 text-white rounded-full flex items-center justify-center text-lg transition-colors"
                >
                  ↑
                </button>
              </div>
            </div>

            {/* Communication hours notice */}
            <div className="bg-gray-50 border border-gray-200 rounded-2xl p-4 text-center">
              <div className="text-xs text-gray-500">⏰ Horario de comunicación: <strong>7:00 – 19:00</strong></div>
              <div className="text-xs text-gray-400 mt-1">Los mensajes fuera de este horario se entregan al día siguiente</div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
