# CV Analyzer — GCP Cloud Run Workshop

Vertex AI ve Gemini destekli, CV'yi is tanimi ile karsilastiran profesyonel bir analiz uygulamasi olusturup Google Cloud Run'a deploy etmeyi ogreten interaktif workshop.

## Baslatmak icin:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/open?git_repo=https://github.com/GDGonCampusPAU/CV-analizer-workshop&tutorial=tutorial.md&cloudshell_git_branch=main)


### Hesap sorunu yasiyorsaniz:

Cloud Shell'i acip su komutlari sirayla calistirin:

```bash
git clone https://github.com/GDGonCampusPAU/CV-analizer-workshop.git
```

```bash
cloudshell launch-tutorial ~/CV-analizer-workshop/tutorial.md
```

Already Exists Hatasi Aliyorsaniz:

```bash
rm -rf ~/CV-analizer-workshop && git clone https://github.com/GDGonCampusPAU/CV-analizer-workshop.git && cloudshell launch-tutorial ~/CV-analizer-workshop/tutorial.md
```

---

## Uygulama Ne Yapar?

PDF formatinda bir CV ve basvurulan pozisyonun is tanimi girildiginde, Gemini AI asagidaki raporu uretir:

- **Guclu Yonler** — Adayin o pozisyon icin one cikan becerileri ve deneyimleri
- **Gelistirilmesi Gereken Alanlar** — CV'deki eksik veya yetersiz kalan noktalar
- **Pozisyon Icin Onerilerin** — O role ozgu eklenmesi gereken beceri, sertifika veya deneyimler

Cikti tamamen emojisiz, profesyonel ve maddeli formattadir. Sistem, CV veya is tanimi alanina gomulmus prompt injection saldirilarini engellemek uzere system_instruction ile kilitlenmistir.

---

## Ne Ogreneceksiniz?

- Cloud Shell kullanimi
- Python Flask ile REST API olusturma
- Docker ile container paketleme
- Vertex AI ve Gemini ile multimodal (PDF) AI entegrasyonu
- Prompt injection guvenlik onlemleri (system_instruction pattern)
- Google Cloud Run'a serverless deploy
- GCP kredi yonetimi ve maliyet takibi

---

## Proje Yapisi

```
cv-analyzer-workshop/
├── cv-analyzer-app/
│   ├── app.py              # Flask backend + Vertex AI entegrasyonu
│   ├── requirements.txt    # Python bagimliliklar
│   ├── Dockerfile          # Container tarifi
│   ├── .gcloudignore       # Cloud Build kapsam disinda birakilacaklar
│   └── templates/
│       └── index.html      # Web arayuzu
├── setup-iam.sh            # GCP IAM izin kurulum scripti
├── deploy.sh               # Cloud Run deploy scripti
└── tutorial.md             # Cloud Shell interaktif tutorial
```

---

## Guvenlik Mimarisi

Uygulama prompt injection saldirilarina karsi iki katmanli koruma uyguluyor:

1. **system_instruction** — Gemini modeline kullanici mesajiyla degistirilemeyen temel rol talimati verilir. Model yalnizca CV analizi yapar.
2. **Sunucu tarafli dogrulama** — PDF magic byte kontrolu ve is tanimi uzunluk siniri, istek Gemini'ye ulasmazan once Python'da dogrulanir.

---

## Mimari

```
Kullanici Browser
      |
      | (PDF + Job Description)
      v
 Cloud Run
 cv-analyzer
      |
      | Part.from_data(pdf_bytes, "application/pdf")
      v
 Vertex AI
 Gemini 2.5 Flash
      |
      v
 Structured Text Report
```

---

*Bu workshop GDG on Campus PAU tarafindan duzenlenmistir.*
