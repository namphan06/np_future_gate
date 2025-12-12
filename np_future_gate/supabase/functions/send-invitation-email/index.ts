import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { candidate_email, candidate_name, job_title, employer_email } = await req.json();

    if (!RESEND_API_KEY) {
      throw new Error("Missing RESEND_API_KEY");
    }

    // 1. Try sending to the real candidate
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: "onboarding@resend.dev",
        to: [candidate_email],
        subject: `Mời ứng tuyển: ${job_title}`,
        html: `
          <h1>Xin chào ${candidate_name},</h1>
          <p>Chúng tôi rất ấn tượng với hồ sơ của bạn và muốn mời bạn ứng tuyển vào vị trí <strong>${job_title}</strong>.</p>
          <p>Vui lòng kiểm tra ứng dụng FutureGate để biết thêm chi tiết.</p>
          <br/>
          <p>Trân trọng,</p>
          <p>${employer_email}</p>
        `,
      }),
    });

    const data = await res.json();

    // 2. Handle Free Tier Restriction (403 Forbidden)
    if (!res.ok) {
      // If Resend blocks it because of Free Tier (sending to unverified email)
      if (res.status === 403 || (data.message && data.message.includes("only send testing emails"))) {
        
        // Fallback: Send to the Admin (You) instead so you can verify the content
        const resFallback = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${RESEND_API_KEY}`,
          },
          body: JSON.stringify({
            from: "onboarding@resend.dev",
            to: ["namphan06124@gmail.com"], // Your registered email
            subject: `[TEST MODE] Gửi cho: ${candidate_name}`,
            html: `
              <div style="background-color: #fff3cd; padding: 15px; border: 1px solid #ffeeba; border-radius: 5px; margin-bottom: 20px;">
                <h3 style="color: #856404; margin-top: 0;">⚠️ Chế độ kiểm thử (Free Tier)</h3>
                <p>Bạn đang dùng gói miễn phí của Resend, nên chỉ có thể gửi email đến chính mình.</p>
                <p>Hệ thống đã <strong>chuyển hướng</strong> email này về hộp thư của bạn để bạn kiểm tra nội dung.</p>
                <p><strong>Người nhận thực tế (dự kiến):</strong> ${candidate_email}</p>
              </div>
              <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;" />
              
              <h1>Xin chào ${candidate_name},</h1>
              <p>Chúng tôi rất ấn tượng với hồ sơ của bạn và muốn mời bạn ứng tuyển vào vị trí <strong>${job_title}</strong>.</p>
              <p>Vui lòng kiểm tra ứng dụng FutureGate để biết thêm chi tiết.</p>
              <br/>
              <p>Trân trọng,</p>
              <p>${employer_email}</p>
            `,
          }),
        });

        if (resFallback.ok) {
          const fallbackData = await resFallback.json();
          // Return success to the app, but with a note
          return new Response(JSON.stringify({ 
            id: fallbackData.id, 
            message: "Sent to admin (Free Tier redirect)" 
          }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 200,
          });
        }
      }

      // If it's another error, return it
      return new Response(JSON.stringify(data), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
