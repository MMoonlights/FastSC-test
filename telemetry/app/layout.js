import "./globals.css";

export const metadata = {
  title: "FastSC Telemetry",
  description: "Opt-in aggregate telemetry and feedback for FastSC",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
