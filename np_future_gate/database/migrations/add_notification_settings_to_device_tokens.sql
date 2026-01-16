-- Migration: Add notification_settings column to device_tokens table
-- Created: 2026-01-16
-- Description: Adds JSONB column for per-device notification preferences

-- 1. Add notification_settings column with default config
ALTER TABLE public.device_tokens 
ADD COLUMN IF NOT EXISTS notification_settings JSONB DEFAULT '{
    "enabled": true,
    "job_notifications": true,
    "application_notifications": true,
    "interview_notifications": true,
    "partnership_notifications": true,
    "message_notifications": true,
    "system_notifications": true,
    "sound_enabled": true,
    "vibration_enabled": true,
    "notification_types": {
        "info": true,
        "success": true,
        "warning": true,
        "error": true,
        "announcement": true,
        "requirement": true,
        "reminder": true
    }
}'::JSONB;

-- 2. Update existing rows to have default settings (if column was NULL)
UPDATE public.device_tokens
SET notification_settings = '{
    "enabled": true,
    "job_notifications": true,
    "application_notifications": true,
    "interview_notifications": true,
    "partnership_notifications": true,
    "message_notifications": true,
    "system_notifications": true,
    "sound_enabled": true,
    "vibration_enabled": true,
    "notification_types": {
        "info": true,
        "success": true,
        "warning": true,
        "error": true,
        "announcement": true,
        "requirement": true,
        "reminder": true
    }
}'::JSONB
WHERE notification_settings IS NULL;

-- 3. Update upsert_device_token function to include notification_settings
CREATE OR REPLACE FUNCTION public.upsert_device_token(
    p_device_id TEXT,
    p_user_id UUID,
    p_role TEXT,
    p_device_type TEXT DEFAULT NULL,
    p_device_name TEXT DEFAULT NULL,
    p_app_version TEXT DEFAULT NULL,
    p_notification_settings JSONB DEFAULT NULL
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
        notification_settings,
        is_active,
        last_login_at
    ) VALUES (
        p_device_id,
        p_user_id,
        p_role,
        p_device_type,
        p_device_name,
        p_app_version,
        COALESCE(p_notification_settings, '{
            "enabled": true,
            "job_notifications": true,
            "application_notifications": true,
            "interview_notifications": true,
            "partnership_notifications": true,
            "message_notifications": true,
            "system_notifications": true,
            "sound_enabled": true,
            "vibration_enabled": true,
            "notification_types": {
                "info": true,
                "success": true,
                "warning": true,
                "error": true,
                "announcement": true,
                "requirement": true,
                "reminder": true
            }
        }'::JSONB),
        true,
        NOW()
    )
    ON CONFLICT (device_id, user_id, role)
    WHERE is_active = true
    DO UPDATE SET
        device_type = COALESCE(EXCLUDED.device_type, device_tokens.device_type),
        device_name = COALESCE(EXCLUDED.device_name, device_tokens.device_name),
        app_version = COALESCE(EXCLUDED.app_version, device_tokens.app_version),
        notification_settings = COALESCE(EXCLUDED.notification_settings, device_tokens.notification_settings),
        is_active = true,
        last_login_at = NOW()
    RETURNING id INTO v_token_id;
    
    RETURN v_token_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Drop and recreate get_user_device_tokens function to return notification_settings
DROP FUNCTION IF EXISTS public.get_user_device_tokens(UUID, TEXT);

CREATE OR REPLACE FUNCTION public.get_user_device_tokens(
    p_user_id UUID,
    p_role TEXT DEFAULT NULL
)
RETURNS TABLE (
    device_id TEXT,
    device_type TEXT,
    notification_settings JSONB,
    last_login_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dt.device_id,
        dt.device_type,
        dt.notification_settings,
        dt.last_login_at
    FROM public.device_tokens dt
    WHERE dt.user_id = p_user_id
    AND dt.is_active = true
    AND (p_role IS NULL OR dt.role = p_role)
    ORDER BY dt.last_login_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Create function to update notification settings
CREATE OR REPLACE FUNCTION public.update_device_notification_settings(
    p_device_id TEXT,
    p_user_id UUID,
    p_settings JSONB
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.device_tokens
    SET notification_settings = p_settings,
        updated_at = NOW()
    WHERE device_id = p_device_id
    AND user_id = p_user_id
    AND is_active = true;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Create function to check if notification should be sent to device
CREATE OR REPLACE FUNCTION public.should_send_notification(
    p_device_id TEXT,
    p_user_id UUID,
    p_notification_category TEXT, -- 'job', 'application', 'interview', 'partnership', 'message', 'system'
    p_notification_type TEXT DEFAULT NULL -- 'info', 'success', 'warning', 'error', 'announcement', 'requirement', 'reminder'
)
RETURNS BOOLEAN AS $$
DECLARE
    v_settings JSONB;
    v_enabled BOOLEAN;
    v_category_enabled BOOLEAN;
    v_type_enabled BOOLEAN;
BEGIN
    -- Get notification settings for device
    SELECT notification_settings INTO v_settings
    FROM public.device_tokens
    WHERE device_id = p_device_id
    AND user_id = p_user_id
    AND is_active = true;
    
    -- If no settings found, return false
    IF v_settings IS NULL THEN
        RETURN false;
    END IF;
    
    -- Check if notifications are enabled globally
    v_enabled := COALESCE((v_settings->>'enabled')::BOOLEAN, true);
    IF NOT v_enabled THEN
        RETURN false;
    END IF;
    
    -- Check if specific category is enabled
    v_category_enabled := COALESCE(
        (v_settings->(p_notification_category || '_notifications'))::BOOLEAN, 
        true
    );
    IF NOT v_category_enabled THEN
        RETURN false;
    END IF;
    
    -- Check if specific notification type is enabled (if provided)
    IF p_notification_type IS NOT NULL THEN
        v_type_enabled := COALESCE(
            (v_settings->'notification_types'->p_notification_type)::BOOLEAN,
            true
        );
        IF NOT v_type_enabled THEN
            RETURN false;
        END IF;
    END IF;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Grant permissions for new functions
GRANT EXECUTE ON FUNCTION public.update_device_notification_settings TO authenticated;
GRANT EXECUTE ON FUNCTION public.should_send_notification TO authenticated;

-- 8. Add comment
COMMENT ON COLUMN public.device_tokens.notification_settings IS 'JSONB settings for notification preferences on this device. Includes enabled flags for different notification categories and types.';

-- 9. Success message
DO $$
BEGIN
    RAISE NOTICE 'Migration completed: notification_settings column added to device_tokens table';
END $$;
