<template>
  <div class="preview-shell" :dir="direction">
    <aside class="sidebar">
      <div class="brand">Frappe HR</div>
      <div class="preview-badge">Preview mode</div>
      <nav>
        <button v-for="item in nav" :key="item.key" :class="['nav-item', { active: active === item.key }]" @click="active = item.key">
          <span class="dot"></span>{{ t(item.key) }}
        </button>
      </nav>
    </aside>

    <main class="content">
      <header class="topbar">
        <div>
          <p class="eyebrow">{{ t('employeePortal') }}</p>
          <h1>{{ t('hello') }}, Youssef</h1>
        </div>
        <div class="top-actions">
          <select v-model="lang" aria-label="Language">
            <option value="en">English</option>
            <option value="fr">Français</option>
            <option value="cs">Čeština</option>
            <option value="ar">العربية</option>
          </select>
          <div class="avatar">YD</div>
        </div>
      </header>

      <section class="notice">
        <strong>{{ t('previewTitle') }}</strong>
        <span>{{ t('previewText') }}</span>
      </section>

      <section class="cards">
        <article class="card">
          <span>{{ t('leaveBalance') }}</span>
          <strong>18.5</strong>
          <small>{{ t('daysAvailable') }}</small>
        </article>
        <article class="card">
          <span>{{ t('attendance') }}</span>
          <strong>96%</strong>
          <small>{{ t('thisMonth') }}</small>
        </article>
        <article class="card">
          <span>{{ t('expenses') }}</span>
          <strong>€240</strong>
          <small>{{ t('awaitingApproval') }}</small>
        </article>
        <article class="card">
          <span>{{ t('documents') }}</span>
          <strong>12</strong>
          <small>{{ t('availableDocuments') }}</small>
        </article>
      </section>

      <section class="grid">
        <article class="panel">
          <div class="panel-head">
            <div>
              <p class="eyebrow">{{ t('quickActions') }}</p>
              <h2>{{ t('whatDoYouNeed') }}</h2>
            </div>
          </div>
          <div class="actions">
            <button>{{ t('requestLeave') }}</button>
            <button>{{ t('submitExpense') }}</button>
            <button>{{ t('viewPayslip') }}</button>
            <button>{{ t('updateProfile') }}</button>
          </div>
        </article>

        <article class="panel">
          <div class="panel-head">
            <div>
              <p class="eyebrow">{{ t('upcoming') }}</p>
              <h2>{{ t('importantDates') }}</h2>
            </div>
          </div>
          <ul class="timeline">
            <li><strong>29 Oct</strong><span>{{ t('payday') }}</span></li>
            <li><strong>2 Nov</strong><span>{{ t('teamReview') }}</span></li>
            <li><strong>17 Nov</strong><span>{{ t('publicHoliday') }}</span></li>
          </ul>
        </article>
      </section>
    </main>
  </div>
</template>

<script setup>
import { computed, ref, watch } from "vue"

const active = ref("home")
const lang = ref("en")
const direction = computed(() => (lang.value === "ar" ? "rtl" : "ltr"))

watch([lang, direction], () => {
  document.documentElement.lang = lang.value
  document.documentElement.dir = direction.value
}, { immediate: true })

const nav = [
  { key: "home" },
  { key: "people" },
  { key: "timeOff" },
  { key: "attendance" },
  { key: "payroll" },
  { key: "expenses" },
  { key: "performance" },
  { key: "documents" },
]

const copy = {
  en: { home:"Home", people:"People", timeOff:"Time off", attendance:"Attendance", payroll:"Payroll", expenses:"Expenses", performance:"Performance", documents:"Documents", employeePortal:"Employee portal", hello:"Hello", previewTitle:"Live design preview", previewText:"Sample data only - no real employee information is connected.", leaveBalance:"Leave balance", daysAvailable:"days available", thisMonth:"this month", awaitingApproval:"awaiting approval", availableDocuments:"available documents", quickActions:"Quick actions", whatDoYouNeed:"What do you need today?", requestLeave:"Request leave", submitExpense:"Submit expense", viewPayslip:"View payslip", updateProfile:"Update profile", upcoming:"Upcoming", importantDates:"Important dates", payday:"Payday", teamReview:"Team review", publicHoliday:"Public holiday" },
  fr: { home:"Accueil", people:"Collaborateurs", timeOff:"Congés", attendance:"Présence", payroll:"Paie", expenses:"Dépenses", performance:"Performance", documents:"Documents", employeePortal:"Portail employé", hello:"Bonjour", previewTitle:"Aperçu de conception en direct", previewText:"Données de démonstration uniquement - aucune donnée réelle d'employé n'est connectée.", leaveBalance:"Solde de congés", daysAvailable:"jours disponibles", thisMonth:"ce mois-ci", awaitingApproval:"en attente d'approbation", availableDocuments:"documents disponibles", quickActions:"Actions rapides", whatDoYouNeed:"De quoi avez-vous besoin aujourd'hui ?", requestLeave:"Demander un congé", submitExpense:"Soumettre une dépense", viewPayslip:"Voir la fiche de paie", updateProfile:"Mettre à jour le profil", upcoming:"À venir", importantDates:"Dates importantes", payday:"Jour de paie", teamReview:"Revue d'équipe", publicHoliday:"Jour férié" },
  cs: { home:"Domů", people:"Lidé", timeOff:"Volno", attendance:"Docházka", payroll:"Mzdy", expenses:"Výdaje", performance:"Výkon", documents:"Dokumenty", employeePortal:"Portál zaměstnance", hello:"Ahoj", previewTitle:"Živý náhled návrhu", previewText:"Pouze ukázková data - nejsou připojena žádná skutečná data zaměstnanců.", leaveBalance:"Zůstatek dovolené", daysAvailable:"dní k dispozici", thisMonth:"tento měsíc", awaitingApproval:"čeká na schválení", availableDocuments:"dostupných dokumentů", quickActions:"Rychlé akce", whatDoYouNeed:"Co dnes potřebujete?", requestLeave:"Požádat o volno", submitExpense:"Odeslat výdaj", viewPayslip:"Zobrazit výplatní pásku", updateProfile:"Aktualizovat profil", upcoming:"Nadcházející", importantDates:"Důležitá data", payday:"Výplatní den", teamReview:"Týmové hodnocení", publicHoliday:"Státní svátek" },
  ar: { home:"الرئيسية", people:"الموظفون", timeOff:"الإجازات", attendance:"الحضور", payroll:"الرواتب", expenses:"المصروفات", performance:"الأداء", documents:"المستندات", employeePortal:"بوابة الموظف", hello:"مرحباً", previewTitle:"معاينة تصميم مباشرة", previewText:"بيانات تجريبية فقط - لا توجد بيانات موظفين حقيقية متصلة.", leaveBalance:"رصيد الإجازات", daysAvailable:"يوم متاح", thisMonth:"هذا الشهر", awaitingApproval:"بانتظار الموافقة", availableDocuments:"مستند متاح", quickActions:"إجراءات سريعة", whatDoYouNeed:"ماذا تحتاج اليوم؟", requestLeave:"طلب إجازة", submitExpense:"تقديم مصروف", viewPayslip:"عرض قسيمة الراتب", updateProfile:"تحديث الملف الشخصي", upcoming:"القادم", importantDates:"تواريخ مهمة", payday:"يوم الراتب", teamReview:"مراجعة الفريق", publicHoliday:"عطلة رسمية" },
}

const t = (key) => copy[lang.value]?.[key] || copy.en[key] || key
</script>

<style scoped>
* { box-sizing: border-box; }
.preview-shell { min-height:100vh; display:grid; grid-template-columns:240px 1fr; background:#f7f8fa; color:#171717; font-family:Inter, ui-sans-serif, system-ui, sans-serif; }
.sidebar { padding:28px 18px; background:#fff; border-inline-end:1px solid #e8e8e8; }
.brand { font-weight:750; font-size:20px; margin-bottom:8px; }
.preview-badge { display:inline-block; font-size:11px; padding:4px 8px; border-radius:999px; background:#eef4ff; color:#315da8; margin-bottom:24px; }
nav { display:flex; flex-direction:column; gap:4px; }
.nav-item { display:flex; align-items:center; gap:10px; width:100%; border:0; background:transparent; border-radius:10px; padding:10px 12px; text-align:start; cursor:pointer; color:#555; }
.nav-item.active { background:#f0f3f6; color:#111; font-weight:650; }
.dot { width:7px; height:7px; border-radius:50%; background:#a8adb5; }
.nav-item.active .dot { background:#222; }
.content { padding:30px 36px 48px; max-width:1400px; width:100%; margin:auto; }
.topbar { display:flex; align-items:center; justify-content:space-between; gap:24px; margin-bottom:24px; }
h1 { font-size:31px; margin:4px 0 0; letter-spacing:-0.03em; }
.eyebrow { margin:0; font-size:12px; text-transform:uppercase; letter-spacing:.08em; color:#777; }
.top-actions { display:flex; align-items:center; gap:12px; }
select { border:1px solid #ddd; border-radius:9px; padding:9px 12px; background:white; }
.avatar { width:40px; height:40px; display:grid; place-items:center; border-radius:50%; background:#242424; color:white; font-size:13px; font-weight:700; }
.notice { display:flex; gap:8px; flex-wrap:wrap; padding:13px 16px; border:1px solid #d7e4ff; background:#f3f7ff; border-radius:12px; margin-bottom:20px; font-size:14px; }
.cards { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:14px; margin-bottom:16px; }
.card,.panel { background:#fff; border:1px solid #e7e7e7; border-radius:14px; }
.card { padding:18px; display:flex; flex-direction:column; gap:4px; }
.card span { color:#666; font-size:13px; }
.card strong { font-size:27px; letter-spacing:-.03em; }
.card small { color:#8a8a8a; }
.grid { display:grid; grid-template-columns:1.5fr 1fr; gap:16px; }
.panel { padding:20px; }
.panel h2 { font-size:19px; margin:5px 0 18px; }
.actions { display:grid; grid-template-columns:1fr 1fr; gap:10px; }
.actions button { min-height:48px; border:1px solid #e2e2e2; background:#fafafa; border-radius:10px; text-align:start; padding:0 14px; font-weight:600; cursor:pointer; }
.timeline { list-style:none; padding:0; margin:0; display:flex; flex-direction:column; gap:14px; }
.timeline li { display:grid; grid-template-columns:70px 1fr; align-items:center; padding:9px 0; border-bottom:1px solid #f0f0f0; }
.timeline li:last-child { border-bottom:0; }
.timeline span { color:#555; }
[dir="rtl"] .topbar,[dir="rtl"] .notice { direction:rtl; }
@media (max-width:900px){ .preview-shell{grid-template-columns:1fr}.sidebar{display:none}.content{padding:22px}.cards{grid-template-columns:1fr 1fr}.grid{grid-template-columns:1fr} }
@media (max-width:560px){ .cards{grid-template-columns:1fr}.topbar{align-items:flex-start}.top-actions{flex-direction:column;align-items:flex-end} }
</style>
