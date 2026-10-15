/** @type {import('next').NextConfig} */
const nextConfig = {
  // "standalone" bundles only the files Next.js actually needs to run in
  // production into .next/standalone — much smaller Docker image than
  // copying the whole node_modules folder in.
  output: "standalone",
  reactStrictMode: true,
};

module.exports = nextConfig;