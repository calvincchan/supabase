// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

import { serve } from "https://deno.land/std@0.182.0/http/server.ts";
import {
  createClient,
  SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface IArguments {
  name: string;
  email: string;
  role: string;
}

const processInput = function ({ name, email, role }: IArguments) {
  return {
    name: String(name).trim(),
    email: String(email).trim().toLowerCase(),
    role: String(role).trim().toUpperCase(),
  };
};

const getCurrentUserRole = async function (
  supabase: SupabaseClient,
  id: string
) {
  const { error, data } = await supabase
    .from("team_member")
    .select("role")
    .eq("id", id);
  if (error) throw error;
  if (data.length !== 1)
    throw new Error("Unable to find current user from team member table.");
  return data[0]?.role || "";
};

serve(async (req: Request) => {
  // This is needed if you're planning to invoke your function from a browser.
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const { name, email, role } = processInput(await req.json());
  try {
    if (!email) throw new Error("Email is required.");
    if (!role) throw new Error("Role is required.");
    if (!["A", "B"].includes(role))
      throw new Error('Role must be one of "A" or "B"');

    /** Create a Supabase client with the Auth context of the logged in user. */
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        auth: { persistSession: false },
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    /** Create a Service client */
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } }
    );

    /** Now we can get current user object. */
    const {
      data: { user: currentUser },
    } = await supabaseClient.auth.getUser();
    if (!currentUser) throw new Error("Unable to get the current user.");

    /** Check if the current user role is a "Manager". */
    const currentUserRole = await getCurrentUserRole(
      supabaseClient,
      currentUser.id
    );
    if (currentUserRole !== "A")
      throw new Error(
        "The current user does not have privilege to invite new member."
      );

    /** Invite new user. */
    const inviteUserRes = await serviceClient.auth.admin.inviteUserByEmail(
      email
    );
    if (inviteUserRes.error) throw inviteUserRes.error;
    const invitedUser = inviteUserRes.data.user;

    /** Insert a new row to team_member. */
    const createTeamMemberRes = await serviceClient.from("team_member").upsert({
      id: invitedUser.id,
      email: invitedUser.email,
      name,
      role,
    });
    if (createTeamMemberRes.error) throw createTeamMemberRes.error;

    return new Response("ok", {
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

// To invoke:
// curl -i --location --request POST 'http://localhost:54321/functions/v1/' \
//   --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
//   --header 'Content-Type: application/json' \
//   --data '{"name":"Functions"}'
