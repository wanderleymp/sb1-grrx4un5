import express from 'express';
import { supabase } from '../services/supabase';

const router = express.Router();

router.post('/', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('licenses')
      .insert(req.body)
      .select()
      .single();

    if (error) throw error;
    res.status(201).json(data);
  } catch (error) {
    console.error('Erro ao criar licença:', error);
    res.status(500).json({ error: 'Não foi possível criar a licença' });
  }
});

router.get('/', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('licenses')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    res.json(data || []);
  } catch (error) {
    console.error('Erro ao buscar licenças:', error);
    res.status(500).json({ error: 'Não foi possível buscar as licenças' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('licenses')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (error) throw error;
    if (!data) {
      return res.status(404).json({ error: 'Licença não encontrada' });
    }
    res.json(data);
  } catch (error) {
    console.error('Erro ao buscar licença:', error);
    res.status(500).json({ error: 'Não foi possível buscar a licença' });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('licenses')
      .update(req.body)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;
    res.json(data);
  } catch (error) {
    console.error('Erro ao atualizar licença:', error);
    res.status(500).json({ error: 'Não foi possível atualizar a licença' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const { error } = await supabase
      .from('licenses')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;
    res.status(204).send();
  } catch (error) {
    console.error('Erro ao deletar licença:', error);
    res.status(500).json({ error: 'Não foi possível deletar a licença' });
  }
});

export default router;