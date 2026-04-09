export const school = {
  name: "Escuela Infantil Sol y Luna",
  logo: "🌙",
};

export const teacher = {
  name: "Laura Martínez",
  classroom: "Aula Girasoles (2-3 años)",
  avatar: "LM",
};

export const director = {
  name: "Carmen García",
  avatar: "CG",
};

export const parent = {
  name: "Sofía Rodríguez",
  child: "Pablo Rodríguez",
  avatar: "SR",
};

export const children = [
  { id: "1", name: "Pablo Rodríguez", present: true, late: false, meal: "bien", nap: "bien", parentNotified: false },
  { id: "2", name: "Lucía Fernández", present: true, late: false, meal: "algo", nap: "inquieta", parentNotified: false },
  { id: "3", name: "Marco Silva", present: false, late: false, meal: null, nap: null, parentNotified: true },
  { id: "4", name: "Valentina López", present: true, late: true, meal: "bien", nap: "bien", parentNotified: false },
  { id: "5", name: "Ahmed Ben Ali", present: true, late: false, meal: "bien", nap: "no durmió", parentNotified: false },
  { id: "6", name: "Mía Castro", present: true, late: false, meal: "algo", nap: "bien", parentNotified: false },
];

export const activities = [
  "Pintura con dedos",
  "Cuento: El pequeño pez",
  "Música y movimiento",
  "Juego libre en el patio",
  "Taller de plastilina",
  "Rincón de lectura",
];

export const messages = [
  {
    id: "1",
    from: "Sofía Rodríguez",
    fromRole: "parent",
    to: "Laura Martínez",
    toRole: "teacher",
    text: "Buenos días Laura, ¿podría Pablo traer ropa de cambio extra mañana?",
    time: "09:12",
    read: true,
    avatar: "SR",
  },
  {
    id: "2",
    from: "Laura Martínez",
    fromRole: "teacher",
    to: "Sofía Rodríguez",
    toRole: "parent",
    text: "¡Claro que sí, Sofía! Sin problema.",
    time: "09:45",
    read: true,
    avatar: "LM",
  },
  {
    id: "3",
    from: "Carmen García",
    fromRole: "director",
    to: "all",
    toRole: "all",
    text: "📢 Recordamos que el viernes 11 de abril no hay clase por festivo local. ¡Buen puente a todos!",
    time: "10:00",
    read: false,
    avatar: "CG",
    broadcast: true,
  },
];

export const dailyReport = {
  date: "Miércoles, 9 de abril de 2026",
  activities: ["Pintura con dedos", "Cuento: El pequeño pez", "Música y movimiento"],
  groupNote: "Ha sido un día muy creativo. Los niños disfrutaron mucho del taller de pintura y estuvieron muy atentos durante el cuento.",
  photos: [
    { id: "1", emoji: "🎨", caption: "Taller de pintura", children: ["Pablo Rodríguez", "Lucía Fernández", "Valentina López"] },
    { id: "2", emoji: "📚", caption: "Hora del cuento", children: ["Pablo Rodríguez", "Ahmed Ben Ali", "Mía Castro"] },
  ],
  childReport: {
    meal: "bien",
    nap: "bien",
    mood: "feliz",
    note: "Pablo ha estado muy participativo hoy. Le ha encantado la pintura y ha hecho un dibujo precioso que llevará a casa.",
  },
};
