# 💼 Portfolio Case Study: Exam Rush Hour

> **Quick Summary:** A full-stack, cross-platform EdTech examination and evaluation application built with **Flutter**, **Dart**, and **Supabase**. Supports automated MCQ assessments, written question paper delivery, student multi-page answer sheet uploads, and a custom digital pen annotation canvas for teacher paper grading.

---

## 📌 Executive Summary & Resume Snippets

### 🎯 One-Line Hook
> *"A cross-platform Flutter and Supabase examination platform featuring instant MCQ auto-grading and an in-app digital pen canvas for evaluating handwritten student exam scripts."*

### 📄 Bullet Points for Resume / CV (STAR Method)
- **Built an end-to-end examination platform** using **Flutter** and **Supabase (PostgreSQL & Cloud Storage)**, serving role-based portals for both educators and students across Web and Mobile.
- **Engineered a custom digital grading canvas (`DrawingBoard`)** utilizing Flutter's `CustomPainter` and `InteractiveViewer`, enabling teachers to digitally annotate, zoom, rotate, and grade student answer papers in real time.
- **Architected reactive state management** with **Riverpod 2.x code generator** and **GoRouter**, creating persistent session recovery and tamper-resistant exam countdown timers.
- **Implemented multi-format file processing pipelines** for high-resolution images and PDFs with **Syncfusion Flutter PDF Viewer**, optimizing bandwidth during bulk student script uploads.

---

## 🚀 The Problem & Solution

### The Challenge
Online examination tools typically suffer from one of two extremes:
1. **Limited to simple MCQs**: Existing lightweight tools fail when testing complex engineering, mathematics, or creative writing exams that require handwritten derivations and diagrams.
2. **Clunky grading workflows**: Teachers grading written exams are forced to download hundreds of student photos, mark them in third-party desktop tools or print them, and manually tally marks into spreadsheets.

### The Solution
**Exam Rush Hour** provides a unified platform:
- **Dual-Mode Tests**: Teachers can create exams featuring either MCQs, Written Subjective tests, or both.
- **Seamless Uploads**: Students take pictures of their handwritten sheets directly or pick them from the gallery, uploading multi-page submissions ordered sequentially.
- **In-App Teacher Evaluation**: Teachers review high-res answer sheets page-by-page directly inside the app, using an integrated red pen annotation tool with pan/zoom and orientation correction, and store marked scripts back into the cloud.
- **Automated Score Aggregation**: MCQ scores are calculated instantaneously upon submission, and written scores are updated dynamically once the instructor completes grading.

---

## 🏗️ Technical Architecture & Key Decisions

### 1. State Management with Riverpod 2.x
- Used code-generated Riverpod notifiers (`@riverpod`) to ensure strict compile-time safety and eliminate runtime state errors.
- Managed complex exam states (selected options, remaining seconds, active page index, uploading states) with clear separation between UI widgets and domain logic.

### 2. Custom Drawing & Annotation Engine
- Designed a custom annotation engine using Flutter's gesture detection and rendering pipeline:
  - Recorded user touch points into vectorized `DrawnPath` objects.
  - Implemented transformation matrix controls (`TransformationController`) to support seamless zooming, panning, and 90-degree rotations for sideways or upside-down student photos.
  - Rendered strokes on top of a `RepaintBoundary` and exported annotated sheets as flattened image buffers directly to Supabase Storage.

### 3. Serverless Backend with Supabase
- **PostgreSQL Database**: Configured relational tables (`exams`, `mcq_questions`, `written_questions`, `submissions`, `written_answers`, `mcq_answers`) with foreign key constraints.
- **Supabase Storage**: Managed high-resolution assets with clean path hierarchies and automatic cleanup of replaced or re-submitted images.
- **Supabase Auth**: Implemented secure token-based user authentication and role-based redirect guards with GoRouter.

---

## 💡 Key Engineering Challenges & How They Were Solved

### Challenge 1: Preserving Drawing Precision Across Rotated / Zoomed Images
- **Problem**: When educators rotate or zoom an uploaded image to read small handwriting, standard gesture coordinates map incorrectly to the transformed image coordinates.
- **Solution**: Decoupled the gesture layer and drawing board state into coordinated layers with stateful `quarterTurns` and transformation matrix inspection, ensuring that pen marks align with the student's handwriting regardless of device orientation or scaling factor.

### Challenge 2: Resilience During Exam Submissions
- **Problem**: Flaky network connections could lead to partial uploads of multi-page written submissions or loss of timer state.
- **Solution**: Built an optimistic local state cache, sequential upload pipeline with individual progress tracking, and an automated background synchronization pattern for student answers.

---

## 📊 Tech Stack Overview

- **Frontend**: Flutter (3.8+), Dart (3.0+), Google Fonts (Inter), Material 3
- **State Management**: Riverpod 2.5 (`flutter_riverpod`, `riverpod_generator`)
- **Navigation**: GoRouter (declarative routing with role-based redirects)
- **Backend & DB**: Supabase (PostgreSQL, Realtime, Auth)
- **Storage**: Supabase Storage Buckets
- **Document Rendering**: `syncfusion_flutter_pdfviewer`
- **Media & Hardware**: `image_picker`, `file_picker`

---

## 🔗 Links & Contacts

- **GitHub Repository**: [https://github.com/saiful16164/Exam-Rush-Hour](https://github.com/saiful16164/Exam-Rush-Hour)
- **Developer**: Saiful Islam ([@saiful16164](https://github.com/saiful16164))
- **Live Demo / Showcase**: Available upon request
