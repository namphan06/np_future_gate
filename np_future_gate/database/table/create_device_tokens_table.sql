-- Create device_tokens table for push notifications
CREATE TABLE IF NOT EXISTS public.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT NOT NULL, -- Unique device identifier (FCM token, APNS token, etc.)
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL, -- User role: 'candidate', 'employer', 'school', 'admin', etc.
    device_type TEXT, -- 'ios' or 'android'
    device_name TEXT, -- Optional: device name/model
    app_version TEXT, -- Optional: app version for tracking
    is_active BOOLEAN DEFAULT true, -- Track if token is still valid
    last_login_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX idx_device_tokens_user_id ON public.device_tokens(user_id);
CREATE INDEX idx_device_tokens_device_id ON public.device_tokens(device_id);
CREATE INDEX idx_device_tokens_role ON public.device_tokens(role);
CREATE INDEX idx_device_tokens_is_active ON public.device_tokens(is_active);

-- Create unique constraint: one device can only have one active token per user+role combination
CREATE UNIQUE INDEX idx_device_tokens_unique_active 
ON public.device_tokens(device_id, user_id, role) 
WHERE is_active = true;

-- Enable Row Level Security
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own device tokens
CREATE POLICY "Users can view own device tokens"
ON public.device_tokens
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert their own device tokens
CREATE POLICY "Users can insert own device tokens"
ON public.device_tokens
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own device tokens
CREATE POLICY "Users can update own device tokens"
ON public.device_tokens
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own device tokens
CREATE POLICY "Users can delete own device tokens"
ON public.device_tokens
FOR DELETE
USING (auth.uid() = user_id);

-- Policy: Admins can view all device tokens
CREATE POLICY "Admins can view all device tokens"
ON public.device_tokens
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_device_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on every update
CREATE TRIGGER trigger_update_device_tokens_updated_at
BEFORE UPDATE ON public.device_tokens
FOR EACH ROW
EXECUTE FUNCTION update_device_tokens_updated_at();

-- Function to upsert device token (register or update existing token)
-- This handles the case where a device logs in with different accounts/roles
CREATE OR REPLACE FUNCTION public.upsert_device_token(
    p_device_id TEXT,
    p_user_id UUID,
    p_role TEXT,
    p_device_type TEXT DEFAULT NULL,
    p_device_name TEXT DEFAULT NULL,
    p_app_version TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_token_id UUID;
BEGIN
    -- First, deactivate any existing tokens for this device with different user/role
    UPDATE public.device_tokens
    SET is_active = false
    WHERE device_id = p_device_id
    AND (user_id != p_user_id OR role != p_role);
    
    -- Insert or update the device token
    INSERT INTO public.device_tokens (
        device_id,
        user_id,
        role,
        device_type,
        device_name,
        app_version,
        is_active,
        last_login_at
    ) VALUES (
        p_device_id,
        p_user_id,
        p_role,
        p_device_type,
        p_device_name,
        p_app_version,
        true,
        NOW()
    )
    ON CONFLICT (device_id, user_id, role)
    WHERE is_active = true
    DO UPDATE SET
        device_type = COALESCE(EXCLUDED.device_type, device_tokens.device_type),
        device_name = COALESCE(EXCLUDED.device_name, device_tokens.device_name),
        app_version = COALESCE(EXCLUDED.app_version, device_tokens.app_version),
        is_active = true,
        last_login_at = NOW()
    RETURNING id INTO v_token_id;
    
    RETURN v_token_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all active device tokens for a user with specific role
CREATE OR REPLACE FUNCTION public.get_user_device_tokens(
    p_user_id UUID,
    p_role TEXT DEFAULT NULL
)
RETURNS TABLE (
    device_id TEXT,
    device_type TEXT,
    last_login_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dt.device_id,
        dt.device_type,
        dt.last_login_at
    FROM public.device_tokens dt
    WHERE dt.user_id = p_user_id
    AND dt.is_active = true
    AND (p_role IS NULL OR dt.role = p_role)
    ORDER BY dt.last_login_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to remove/deactivate a device token
CREATE OR REPLACE FUNCTION public.remove_device_token(
    p_device_id TEXT,
    p_user_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.device_tokens
    SET is_active = false
    WHERE device_id = p_device_id
    AND user_id = p_user_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.device_tokens TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_device_token TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_device_tokens TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_device_token TO authenticated;

-- Add comment to table
COMMENT ON TABLE public.device_tokens IS 'Stores device tokens for push notifications. Updates when user logs in with different accounts/roles.';
