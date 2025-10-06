import type { APIRoute } from "astro";
import { Chart, PieController, ArcElement, Legend, Colors } from 'chart.js';
import { Canvas } from "skia-canvas";
import { getSession } from "@/models/Game.ts";
import { api404 } from "@/utils/api.ts";

Chart.register([
  PieController,
  ArcElement,
  Legend
]);

export const prerender = false

export const GET: APIRoute = async ({ params, request }) => {
  console.debug(params)
  if(!params.id) return api404("MISSING_SESSION_ID", "A session ID is required")
  const session = await getSession(params.id)
  if(!session) return api404("SESSION_NOT_FOUND", "Session was not found")
  if(params.type === "specials") {
    const canvas = new Canvas(400, 300);
    const chart = new Chart(
      canvas as any, // TypeScript needs "as any" here
      {
        type: "pie",
        data: {
          labels: [
            'Smoker',
            'Jockey',
            'Hunter',
            'Charger',
            'Spitter',
            'Charger'
          ],
          datasets: [{
            label: 'Special Kills',
            data: [session.smoker_kills, session.jockey_kills, session.hunter_kills, session.charger_kills, session.spitter_kills, session.charger_kills],
            backgroundColor: [
              "rgb(66, 88, 255)",
              "rgb(248, 131, 48)",
              "rgb(153, 224, 255)",
              "rgb(75, 195, 141)",
              "rgb(255, 183, 15)",
              "rgb(255, 102, 133)"
            ]
          }]
        },
        options: {
          
          plugins: {
            legend: {
              position: 'top',
            }
          }
        }
      }
    );
    const pngBuffer = await canvas.toBuffer('svg');
    chart.destroy()
    //@ts-expect-error -- pngBuffer works fine here
    return new Response(pngBuffer, {
      headers: {
        'Content-Type': 'image/svg+xml',
        // 'Cache-Control': 'public, immutable, max-age=86400, s-maxage=172800, stale-while-revalidate=604800, stale-if-error=604800'
      }
    })
  }

  return new Response(JSON.stringify({
    error: "UNKNOWN_CHART_TYPE",
    message: "Supported charts are 'special'"
  }), {
    status: 404
  });
}
